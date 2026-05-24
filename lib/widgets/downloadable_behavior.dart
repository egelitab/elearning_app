import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import '../services/api_service.dart';
import '../dashboards/file_viewer_screen.dart';

class DownloadableBehavior extends StatefulWidget {
  final String filePath;
  final String fileName;
  final Widget Function(
    BuildContext context, 
    bool isDownloaded, 
    bool isDownloading, 
    bool isPaused, 
    double? progress, 
    Future<void> Function() onTap
  ) builder;

  const DownloadableBehavior({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.builder,
  });

  @override
  State<DownloadableBehavior> createState() => _DownloadableBehaviorState();
}

class _DownloadableBehaviorState extends State<DownloadableBehavior> {
  final ApiService _apiService = ApiService();
  bool _isDownloaded = false;
  bool _isDownloading = false;
  bool _isPaused = false;
  double? _progress;
  
  StreamSubscription<List<int>>? _subscription;
  IOSink? _fileSink;
  File? _targetFile;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _fileSink?.close();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (widget.filePath.isEmpty) return;
    bool downloaded = await _apiService.isFileDownloaded(widget.filePath, fileName: widget.fileName);
    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
      });
    }
  }
  
  Future<void> _handleTap() async {
    if (_isDownloaded) {
      await _openFile();
    } else if (_isDownloading) {
      if (_isPaused) {
        _resumeDownload();
      } else {
        _pauseDownload();
      }
    } else {
      await _startDownload();
    }
  }

  void _pauseDownload() {
    _subscription?.pause();
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeDownload() {
    _subscription?.resume();
    setState(() {
      _isPaused = false;
    });
  }

  Future<void> _startDownload() async {
    if (widget.filePath.isEmpty) return;
    setState(() {
      _isDownloading = true;
      _isPaused = false;
      _progress = 0.0;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      String normalizedPath = widget.filePath.replaceAll('\\', '/');
      String url;
      if (normalizedPath.startsWith('http')) {
        url = normalizedPath;
      } else {
        String cleanBaseUrl = ApiService.baseUrl.replaceAll('/api', '');
        if (normalizedPath.contains(':/')) {
          int uploadsIdx = normalizedPath.indexOf('/uploads/');
          if (uploadsIdx != -1) {
            normalizedPath = normalizedPath.substring(uploadsIdx);
          }
        }
        if (!normalizedPath.startsWith('/') && !cleanBaseUrl.endsWith('/')) {
          url = '$cleanBaseUrl/$normalizedPath';
        } else if (normalizedPath.startsWith('/') && cleanBaseUrl.endsWith('/')) {
           url = cleanBaseUrl + normalizedPath.substring(1);
        } else {
          url = '$cleanBaseUrl$normalizedPath';
        }
      }

      final request = http.Request('GET', Uri.parse(Uri.encodeFull(url)));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        Directory dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download/ELMS');
        } else {
          dir = Directory('${(await getApplicationDocumentsDirectory()).path}/ELMS');
        }
        
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        
        String finalFileName = widget.fileName;
        if (!finalFileName.contains('.') && widget.filePath.contains('.')) {
          final ext = widget.filePath.split('.').last;
          finalFileName = "$finalFileName.$ext";
        }
        if (finalFileName.isEmpty || !finalFileName.contains('.')) {
          finalFileName = "file_${DateTime.now().millisecondsSinceEpoch}.bin";
        }
        
        _targetFile = File('${dir.path}/$finalFileName');
        _fileSink = _targetFile!.openWrite();

        int totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;

        _subscription = response.stream.listen(
          (List<int> chunk) {
            _fileSink?.add(chunk);
            receivedBytes += chunk.length;
            if (totalBytes > 0 && mounted) {
              setState(() {
                _progress = receivedBytes / totalBytes;
              });
            }
          },
          onDone: () async {
            await _fileSink?.flush();
            await _fileSink?.close();
            if (mounted) {
              setState(() {
                _isDownloading = false;
                _isDownloaded = true;
                _progress = 1.0;
              });
            }
          },
          onError: (e) async {
            await _fileSink?.close();
            if (mounted) {
              setState(() {
                _isDownloading = false;
                _isPaused = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
            }
          },
          cancelOnError: true,
        );
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _isPaused = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start download: $e')));
      }
    }
  }

  Future<void> _openFile() async {
    if (_targetFile == null) {
      // Find the file if it was previously downloaded
      Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download/ELMS');
      } else {
        dir = Directory('${(await getApplicationDocumentsDirectory()).path}/ELMS');
      }
      String finalFileName = widget.fileName;
      if (!finalFileName.contains('.') && widget.filePath.contains('.')) {
        final ext = widget.filePath.split('.').last;
        finalFileName = "$finalFileName.$ext";
      }
      _targetFile = File('${dir.path}/$finalFileName');
    }

    if (await _targetFile!.exists()) {
      if (['txt', 'docx', 'pptx', 'xlsx', 'doc', 'ppt', 'xls', 'pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp']
          .contains(_targetFile!.path.split('.').last.toLowerCase())) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FileViewerScreen(filePath: _targetFile!.path, fileName: widget.fileName)
          ),
        );
      } else {
        final result = await OpenFilex.open(_targetFile!.path);
        if (result.type != ResultType.done) {
          throw Exception(result.message);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _isDownloaded, _isDownloading, _isPaused, _progress, _handleTap);
  }
}
