import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _calendars = [];

  @override
  void initState() {
    super.initState();
    _fetchCalendars();
  }

  Future<void> _fetchCalendars() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final calendars = await _apiService.getCalendars();
      if (mounted) {
        setState(() => _calendars = calendars);
      }
    } catch (e) {
      debugPrint("Error fetching calendars: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF05398F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Academic Calendar", style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchCalendars,
            child: _calendars.isEmpty 
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: _buildEmptyState(),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _calendars.length,
                  itemBuilder: (context, index) {
                    final calendar = _calendars[index];
                    return _buildCalendarItem(calendar);
                  },
                ),
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          const Text("No academic calendars uploaded yet.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("Updates from admin will appear here.", style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCalendarItem(dynamic calendar) {
    final String title = calendar['title'] ?? "Academic Calendar";
    final String year = calendar['academic_year'] ?? "Unknown Year";
    final String path = calendar['file_path'] ?? "";
    final String fileName = path.split('\\').last.split('/').last;
    final String extension = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : "";

    IconData iconData = Icons.picture_as_pdf_rounded;
    Color iconColor = Colors.redAccent;

    if (['jpg', 'jpeg', 'png'].contains(extension)) {
      iconData = Icons.image_rounded;
      iconColor = Colors.blue;
    } else if (['doc', 'docx'].contains(extension)) {
      iconData = Icons.description_rounded;
      iconColor = Colors.blue.shade800;
    } else if (['xls', 'xlsx'].contains(extension)) {
      iconData = Icons.table_chart_rounded;
      iconColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (path.isNotEmpty) {
              try {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening calendar..."), duration: Duration(seconds: 1)));
                await _apiService.downloadAndOpenFile(path, context: context, fileName: fileName);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                }
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: FutureBuilder<bool>(
                    future: path.isNotEmpty ? _apiService.isFileDownloaded(path) : Future.value(false),
                    builder: (context, snapshot) {
                      IconData currentIcon = iconData;
                      Color currentColor = iconColor;
                      if (snapshot.connectionState == ConnectionState.done && snapshot.data == false) {
                        currentIcon = Icons.download_rounded;
                        currentColor = Colors.grey;
                      }
                      return Icon(currentIcon, color: currentColor, size: 30);
                    }
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF05398F))),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("Year: $year", style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(fileName, style: TextStyle(color: Colors.grey.shade400, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black12, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
