import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:microsoft_viewer/domain/common_processor.dart';
import 'package:microsoft_viewer/domain/spreadsheet_processor.dart';
import 'package:microsoft_viewer/domain/word_processor.dart';
import 'package:microsoft_viewer/models/document.dart';
import 'package:microsoft_viewer/models/font_details.dart';
import 'package:microsoft_viewer/models/foot_end_note.dart';
import 'package:microsoft_viewer/models/presentation.dart';
import 'package:microsoft_viewer/models/relationship.dart';
import 'package:microsoft_viewer/models/spreadsheet.dart';
import 'package:microsoft_viewer/models/styles.dart';
import 'package:microsoft_viewer/utils/odttf.dart';
import 'package:microsoft_viewer/widget/progress_indicator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart' as xml;
import 'package:microsoft_viewer/models/shared_string.dart';

// Use our custom processor
import 'custom_presentation_processor.dart';

class CustomMicrosoftViewer extends StatefulWidget {
  final List<int> fileBytes;

  const CustomMicrosoftViewer(this.fileBytes, {super.key});

  @override
  State<StatefulWidget> createState() => CustomMicrosoftViewerState();
}

class CustomMicrosoftViewerState extends State<CustomMicrosoftViewer> {
  ZipDecoder? _zipDecoder;
  String wordOutputDirectory = "";
  String spreadSheetOutputDirectory = "";
  String presentationOutputDirectory = "";
  String fileType = "";
  late Archive archive;
  List<Relationship> relationShips = [];
  List<SharedString> sharedStrings = [];
  int elementDepth = 0;
  Document wordDocument = Document("empty word document");
  Presentation presentation = Presentation("empty presentation document");
  SpreadSheet spreadSheet = SpreadSheet("empty spread sheet");
  List<Styles> stylesList = [];
  List<Widget> wordWidgets = [];
  List<Widget> spreadSheetWidgets = [];
  List<Widget> presentationWidgets = [];
  List<FontDetails> fontList = [];
  List<FootEndNote> footNotes = [];
  List<FootEndNote> endNotes = [];
  bool showProgressBar = true;

  @override
  void initState() {
    parseAndShowData();
    super.initState();
  }

  Future<void> parseAndShowData() async {
    try {
      debugPrint("Starting to parse document...");
      _zipDecoder ??= ZipDecoder();
      archive = _zipDecoder!.decodeBytes(widget.fileBytes);
      await setupDirectory();
      
      if (archive.any((f) => f.name == 'word/document.xml')) {
        fileType = "word";
      } else if (archive.any((f) => f.name == 'xl/workbook.xml')) {
        fileType = "spreadsheet";
      } else if (archive.any((f) => f.name == 'ppt/presentation.xml')) {
        fileType = "presentation";
      }

      debugPrint("File type detected: $fileType");

      if (fileType == "word") {
        var relFile = archive.singleWhere((f) => f.name.endsWith("document.xml.rels"));
        getRelationships(relFile);
        archive.where((f) => f.name.startsWith('word/media/')).forEach((f) => extractMedia(f, wordOutputDirectory));
        var stylesFile = archive.singleWhere((f) => f.name.endsWith("word/styles.xml"));
        Map<String, String> defaultValues = {};
        CommonProcessor().processStylesFile(stylesFile, stylesList, defaultValues);
        if (defaultValues.isNotEmpty) {
          if (defaultValues["fontSize"] != null) wordDocument.defaultFontSize = int.parse(defaultValues["fontSize"]!);
          if (defaultValues["lineSpacing"] != null) wordDocument.defaultLineSpacing = int.parse(defaultValues["lineSpacing"]!);
        }
        var fontTable = archive.singleWhereOrNull((f) => f.name.endsWith("word/fontTable.xml"));
        if (fontTable != null) {
          var fontTableRel = archive.singleWhereOrNull((f) => f.name.endsWith("_rels/fontTable.xml.rels"));
          if (fontTableRel != null) {
            CommonProcessor().processFonts(fontList, fontTable, fontTableRel);
            for (var font in fontList) {
              var fontFile = archive.singleWhereOrNull((f) => f.name.endsWith(font.fileName));
              if (fontFile != null) await loadFonts(fontFile, font.name, font.fontKey.replaceAll("{", "").replaceAll("}", ""));
            }
          }
        }
        var footNoteFile = archive.singleWhereOrNull((f) => f.name.endsWith("footnotes.xml"));
        var endNoteFile = archive.singleWhereOrNull((f) => f.name.endsWith("endnotes.xml"));
        WordProcessor().processFootEndNotes(footNoteFile, endNoteFile, footNotes, endNotes);
        var wordFile = archive.singleWhere((f) => f.name == 'word/document.xml');
        WordProcessor().processWordFile(wordFile, elementDepth, relationShips, wordOutputDirectory, stylesList, wordDocument, fileType);
        List<Widget> tempWidgets = WordProcessor().displayWordFile(fileType, wordDocument, stylesList, footNotes, endNotes);
        if (mounted) setState(() { wordWidgets = tempWidgets; showProgressBar = false; });
      } else if (fileType == "spreadsheet") {
        var relFile = archive.singleWhere((f) => f.name.endsWith("workbook.xml.rels"));
        getRelationships(relFile);
        var shareStringsFile = archive.singleWhere((f) => f.name.endsWith("sharedStrings.xml"));
        getSharedStrings(shareStringsFile);
        var workbookFile = archive.singleWhere((f) => f.name.endsWith("xl/workbook.xml"));
        SpreadsheetProcessor().getSpreadSheetDetails(workbookFile, spreadSheet);
        SpreadsheetProcessor().readAllSheets(spreadSheet, relationShips, archive);
        List<Widget> tempWidgets = await SpreadsheetProcessor().displaySpreadSheet(spreadSheet, sharedStrings);
        if (mounted) setState(() { spreadSheetWidgets = tempWidgets; showProgressBar = false; });
      } else if (fileType == "presentation") {
        var relFile = archive.singleWhere((f) => f.name.endsWith("presentation.xml.rels"));
        getRelationships(relFile);
        archive.where((f) => f.name.startsWith('ppt/media/')).forEach((f) => extractMedia(f, presentationOutputDirectory));
        var presentationFile = archive.singleWhere((f) => f.name.endsWith("ppt/presentation.xml"));
        
        CustomPresentationProcessor().getPresentationDetails(presentationFile, presentation);
        CustomPresentationProcessor().readAllSlides(presentation, relationShips, archive, presentationOutputDirectory);
        
        // Calculate screen width to pass to processor
        double sw = MediaQuery.of(context).size.width - 32;

        List<Widget> tempWidgets = await CustomPresentationProcessor().displayPresentation(presentation, sw);
        if (mounted) setState(() { presentationWidgets = tempWidgets; showProgressBar = false; });
      }
    } catch (e, stack) {
      debugPrint("Error parsing data: $e");
      debugPrint(stack.toString());
      if (mounted) setState(() { showProgressBar = false; });
    }
  }

  Future<void> setupDirectory() async {
    var supportDir = await getApplicationSupportDirectory();
    wordOutputDirectory = "${supportDir.path}/word/";
    spreadSheetOutputDirectory = "${supportDir.path}/spreadSheet/";
    presentationOutputDirectory = "${supportDir.path}/presentation/";
    
    [wordOutputDirectory, spreadSheetOutputDirectory, presentationOutputDirectory].forEach((path) {
      var dir = Directory(path);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
    });
  }

  void getRelationships(ArchiveFile relFile) {
    final fileContent = utf8.decode(relFile.content);
    final document = xml.XmlDocument.parse(fileContent);
    relationShips = document.findAllElements("Relationship").map((rel) => 
      Relationship(rel.getAttribute("Id") ?? "", rel.getAttribute("Target") ?? "")
    ).toList();
  }

  void getSharedStrings(ArchiveFile shareStringsFile) {
    var document = xml.XmlDocument.parse(utf8.decode(shareStringsFile.content));
    sharedStrings = document.findAllElements('si').indexed.map((e) => 
      SharedString(e.$1, e.$2.getElement("t")?.innerText ?? "")
    ).toList();
  }

  void extractMedia(ArchiveFile mediaFile, String dirPath) {
    File(dirPath + mediaFile.name.split("/").last).writeAsBytesSync(mediaFile.content as List<int>);
  }

  Future<void> loadFonts(ArchiveFile fontFile, String fontFamily, String fileName) async {
    ODTTF().deobfuscate(fontFile.content, fileName);
    await (FontLoader(fontFamily)..addFont(Future.value(ByteData.view(fontFile.content.buffer)))).load();
  }

  @override
  Widget build(BuildContext context) {
    // Determine which widgets to show
    List<Widget> content = [];
    if (fileType == "word") content = wordWidgets;
    else if (fileType == "spreadsheet") content = spreadSheetWidgets;
    else if (fileType == "presentation") content = presentationWidgets;

    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 1.0, 
            maxScale: 4.0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: content,
                ),
              ),
            ),
          ),
        ),
        if (showProgressBar) const ProgressIndicatorView(),
      ],
    );
  }
}
