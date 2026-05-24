import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:microsoft_viewer/models/presentation.dart';
import 'package:microsoft_viewer/models/relationship.dart';
import 'package:xml/xml.dart' as xml;

// We can still use models from the original package
import 'package:microsoft_viewer/models/presentation_paragraph.dart';
import 'package:microsoft_viewer/models/presentation_shape.dart';
import 'package:microsoft_viewer/models/presentation_text.dart';
import 'package:microsoft_viewer/models/presentation_text_box.dart';
import 'package:microsoft_viewer/models/slide.dart';

/// Class for processing .pptx files (Custom to remove horizontal scroll)
class CustomPresentationProcessor {
  static final Map<int, Size> _slideSizes = {};

  void getPresentationDetails(ArchiveFile presentationFile, Presentation presentation) {
    final fileContent = utf8.decode(presentationFile.content);
    final presentationDoc = xml.XmlDocument.parse(fileContent);

    // Extract slide size
    var sldSz = presentationDoc.findAllElements("p:sldSz").firstOrNull;
    if (sldSz != null) {
      var cx = sldSz.getAttribute("cx");
      var cy = sldSz.getAttribute("cy");
      if (cx != null && cy != null) {
        // Convert EMU to points (1 point = 12700 EMU)
        double w = double.parse(cx) / 12700;
        double h = double.parse(cy) / 12700;
        _slideSizes[presentation.hashCode] = Size(w, h);
      }
    }
    var slidesRoot = presentationDoc.findAllElements("p:sldIdLst");
    if (slidesRoot.isNotEmpty) {
      var slides = slidesRoot.first.findAllElements("p:sldId");
      if (slides.isNotEmpty) {
        for (var slide in slides) {
          int id = 0;
          String rId = "";
          var tempId = slide.getAttribute("id");
          if (tempId != null) id = int.parse(tempId);
          var tempRid = slide.getAttribute("r:id");
          if (tempRid != null) rId = tempRid;
          presentation.slides.add(Slide(id, rId, ""));
        }
      }
    }
    var masterSlidesRoot = presentationDoc.findAllElements("p:sldMasterIdLst");
    if (masterSlidesRoot.isNotEmpty) {
      var masterSlides = masterSlidesRoot.first.findAllElements("p:sldMasterId");
      if (masterSlides.isNotEmpty) {
        for (var slide in masterSlides) {
          int id = 0;
          String rId = "";
          var tempId = slide.getAttribute("id");
          if (tempId != null) id = int.parse(tempId);
          var tempRid = slide.getAttribute("r:id");
          if (tempRid != null) rId = tempRid;
          presentation.masterSlides.add(Slide(id, rId, ""));
        }
      }
    }
  }

  void getAllShapes(ArchiveFile presentationFile, Slide slide) {
    final fileContent = utf8.decode(presentationFile.content);
    final diagramDoc = xml.XmlDocument.parse(fileContent);
    var diagramsRoot = diagramDoc.findAllElements("dsp:sp");
    if (diagramsRoot.isNotEmpty) {
      for (var diagram in diagramsRoot) {
        String id = "";
        String text = "";
        double offsety = 0;
        Offset offset = const Offset(0, 0);
        Size size = const Size(0, 0);
        var tempId = diagram.getAttribute("modelId");
        if (tempId != null) id = tempId;
        var checkTxtBody = diagram.findAllElements("dsp:txBody");
        if (checkTxtBody.isNotEmpty) {
          var checkParaElement = checkTxtBody.first.findAllElements("a:p");
          if (checkParaElement.isNotEmpty) {
            var txtElement = checkParaElement.first.findAllElements("a:t");
            if (txtElement.isNotEmpty) text = txtElement.first.innerText;
          }
        }
        var checkSlFrm = diagram.findAllElements("a:xfrm");
        if (checkSlFrm.isNotEmpty) {
          var checkOffE = checkSlFrm.first.findAllElements("a:off");
          if (checkOffE.isNotEmpty) {
            var tempY = checkOffE.first.getAttribute("y");
            if (tempY != null) offsety = double.parse(tempY);
          }
        }
        var checkTxFrm = diagram.findAllElements("dsp:txXfrm");
        if (checkTxFrm.isNotEmpty) {
          var checkOffE = checkTxFrm.first.findAllElements("a:off");
          if (checkOffE.isNotEmpty) {
            double x = 0;
            double y = 0;
            var tempX = checkOffE.first.getAttribute("x");
            if (tempX != null) x = double.parse(tempX);
            var tempY = checkOffE.first.getAttribute("y");
            if (tempY != null) y = double.parse(tempY);
            offset = Offset(x, y + offsety);
          }
          var checkExtE = checkTxFrm.first.findAllElements("a:ext");
          if (checkExtE.isNotEmpty) {
            double x = 0;
            double y = 0;
            var tempX = checkExtE.first.getAttribute("cx");
            if (tempX != null) x = double.parse(tempX);
            var tempY = checkExtE.first.getAttribute("cy");
            if (tempY != null) y = double.parse(tempY);
            size = Size(x, y);
          }
        }
        slide.presentationShapes.add(PresentationShape(id, text, offset, size));
      }
    }
  }

  void readAllSlides(Presentation presentation, List<Relationship> relationShips, Archive archive, String presentationOutputDirectory) {
    final Map<String, ArchiveFile> fileMap = {};
    for (var f in archive) { fileMap[f.name] = f; }
    
    for (int i = 0; i < presentation.slides.length; i++) {
      var slideRelation = relationShips.firstWhereOrNull((rel) => rel.id == presentation.slides[i].rId);
      if (slideRelation == null) continue;

      String target = slideRelation.target;
      if (!target.startsWith("ppt/")) target = "ppt/$target";
      var slideFile = fileMap[target] ?? archive.singleWhereOrNull((f) => f.name.endsWith(target.split('/').last));
      
      if (slideFile != null && slideFile.isFile) {
        final slideDoc = xml.XmlDocument.parse(utf8.decode(slideFile.content));
        presentation.slides[i].fileName = slideFile.name.split("/").last;

        // Parse slide relationships
        List<Relationship> slideRels = _parseRels("${presentation.slides[i].fileName}.rels", fileMap, archive);
        
        // Find p:spTree
        var spTree = slideDoc.findAllElements("p:spTree").firstOrNull;
        if (spTree != null) {
          _processShapesInTree(spTree, presentation.slides[i], slideRels, presentationOutputDirectory);
        }

        // Improved Background Logic: Slide -> Layout -> Master
        _resolveBackground(slideDoc, presentation.slides[i], slideRels, fileMap, presentationOutputDirectory);
      }
    }
  }

  void _processShapesInTree(xml.XmlElement tree, Slide slide, List<Relationship> slideRels, String outputDir) {
    // Process all shapes and pics, accounting for nesting
    var elements = tree.descendants.whereType<xml.XmlElement>().where((e) => e.name.local == "sp" || e.name.local == "pic");
    
    for (var element in elements) {
      _processSingleElement(element, slide, slideRels, outputDir);
    }
  }

  void _processSingleElement(xml.XmlElement element, Slide slide, List<Relationship> slideRels, String outputDir) {
    // Cumulative Transformation
    double x = 0, y = 0, w = 0, h = 0;
    
    // Get local transform
    var xfrm = element.findAllElements("a:xfrm").firstOrNull;
    if (xfrm != null) {
      var off = xfrm.getElement("a:off");
      var ext = xfrm.getElement("a:ext");
      if (off != null) {
        x = double.tryParse(off.getAttribute("x") ?? "0") ?? 0;
        y = double.tryParse(off.getAttribute("y") ?? "0") ?? 0;
      }
      if (ext != null) {
        w = double.tryParse(ext.getAttribute("cx") ?? "0") ?? 0;
        h = double.tryParse(ext.getAttribute("cy") ?? "0") ?? 0;
      }
    }

    // Apply recursive group transforms up the tree
    var ancestors = element.ancestors.whereType<xml.XmlElement>().where((e) => e.name.local == "grpSp");
    for (var group in ancestors) {
      var gXfrm = group.getElement("p:grpSpPr")?.getElement("a:xfrm");
      if (gXfrm != null) {
        var goff = gXfrm.getElement("a:off");
        var gext = gXfrm.getElement("a:ext");
        var gchoff = gXfrm.getElement("a:chOff");
        var gchext = gXfrm.getElement("a:chExt");

        if (goff != null && gext != null && gchoff != null && gchext != null) {
          double gox = double.tryParse(goff.getAttribute("x") ?? "0") ?? 0;
          double goy = double.tryParse(goff.getAttribute("y") ?? "0") ?? 0;
          double gex = double.tryParse(gext.getAttribute("cx") ?? "1") ?? 1;
          double gey = double.tryParse(gext.getAttribute("cy") ?? "1") ?? 1;
          double gcx = double.tryParse(gchoff.getAttribute("x") ?? "0") ?? 0;
          double gcy = double.tryParse(gchoff.getAttribute("y") ?? "0") ?? 0;
          double gcex = double.tryParse(gchext.getAttribute("cx") ?? "1") ?? 1;
          double gcey = double.tryParse(gchext.getAttribute("cy") ?? "1") ?? 1;

          double sx = gex / gcex;
          double sy = gey / gcey;
          
          x = gox + (x - gcx) * sx;
          y = goy + (y - gcy) * sy;
          w *= sx;
          h *= sy;
        }
      }
    }

    Offset offset = Offset(x, y);
    Size size = Size(w, h);

    if (element.name.local == "sp") {
      List<PresentationParagraph> paras = [];
      for (var txt in element.findAllElements("p:txBody")) {
        for (var para in txt.findAllElements("a:p")) {
          List<PresentationText> texts = [];
          for (var r in para.findAllElements("a:r")) {
            double fs = (double.tryParse(r.getElement("a:rPr")?.getAttribute("sz") ?? "1800") ?? 1800) / 100;
            var t = r.getElement("a:t")?.innerText ?? "";
            if (t.isNotEmpty) texts.add(PresentationText(t, fs));
          }
          if (texts.isNotEmpty) {
            PresentationParagraph p = PresentationParagraph();
            p.textSpans = texts;
            paras.add(p);
          }
        }
      }
      if (paras.isNotEmpty) {
        PresentationTextBox box = PresentationTextBox(offset, size);
        box.presentationParas = paras;
        slide.presentationTextBoxes.add(box);
      } else {
        // Empty shape or stylized shape - give it a generic indicator for now
        slide.presentationShapes.add(PresentationShape("shape", "", offset, size));
      }
    } else if (element.name.local == "pic") {
      var embed = element.findAllElements("a:blip").firstOrNull?.getAttribute("r:embed");
      if (embed != null) {
        var rel = slideRels.firstWhereOrNull((r) => r.id == embed);
        if (rel != null) {
          String imgName = rel.target.split('/').last;
          slide.presentationShapes.add(PresentationShape("image", "IMG|$outputDir$imgName", offset, size));
        }
      }
    }
  }

  void _resolveBackground(xml.XmlDocument doc, Slide slide, List<Relationship> rels, Map<String, ArchiveFile> fileMap, String outputDir) {
    // 1. Direct Background
    var bg = doc.findAllElements("p:bg").firstOrNull;
    if (_applyBackground(bg, slide, rels, outputDir)) return;

    // 2. Layout Background
    var layoutRel = rels.firstWhereOrNull((r) => r.target.contains("slideLayout"));
    if (layoutRel != null) {
      String path = layoutRel.target;
      if (!path.startsWith("ppt/")) path = "ppt/${path.replaceAll("../", "")}";
      var lFile = fileMap[path];
      if (lFile != null) {
        var lDoc = xml.XmlDocument.parse(utf8.decode(lFile.content));
        var lRels = _parseRels("${path.split('/').last}.rels", fileMap, null);
        if (_applyBackground(lDoc.findAllElements("p:bg").firstOrNull, slide, lRels, outputDir)) return;
        
        // 3. Master Background
        var masterRel = lRels.firstWhereOrNull((r) => r.target.contains("slideMaster"));
        if (masterRel != null) {
          String mPath = masterRel.target;
          if (!mPath.startsWith("ppt/")) mPath = "ppt/${mPath.replaceAll("../", "")}";
          var mFile = fileMap[mPath];
          if (mFile != null) {
            var mDoc = xml.XmlDocument.parse(utf8.decode(mFile.content));
            var mRels = _parseRels("${mPath.split('/').last}.rels", fileMap, null);
            _applyBackground(mDoc.findAllElements("p:bg").firstOrNull, slide, mRels, outputDir);
          }
        }
      }
    }
  }

  bool _applyBackground(xml.XmlElement? bg, Slide slide, List<Relationship> rels, String outputDir) {
    if (bg == null) return false;
    var blip = bg.findAllElements("a:blip").firstOrNull;
    var embed = blip?.getAttribute("r:embed");
    if (embed != null) {
      var rel = rels.firstWhereOrNull((r) => r.id == embed);
      if (rel != null) {
        slide.backgroundImagePath = "$outputDir${rel.target.split('/').last}";
        return true;
      }
    }
    return false;
  }

  List<Relationship> _parseRels(String fileName, Map<String, ArchiveFile> fileMap, Archive? archive) {
    List<Relationship> result = [];
    String path = fileName.endsWith(".rels") ? fileName : "$fileName.rels";
    if (!path.contains("_rels/")) {
      if (path.contains("slide")) path = "ppt/slides/_rels/$path";
      else if (path.contains("slideLayout")) path = "ppt/slideLayouts/_rels/$path";
      else if (path.contains("slideMaster")) path = "ppt/slideMasters/_rels/$path";
    }
    
    var file = fileMap[path];
    if (file == null && archive != null) file = archive.singleWhereOrNull((f) => f.name.endsWith(path.split('/').last));
    
    if (file != null) {
      var doc = xml.XmlDocument.parse(utf8.decode(file.content));
      for (var rel in doc.findAllElements("Relationship")) {
        var id = rel.getAttribute("Id");
        var target = rel.getAttribute("Target");
        if (id != null && target != null) result.add(Relationship(id, target));
      }
    }
    return result;
  }

  Future<List<Widget>> displayPresentation(Presentation presentation, double screenWidth) async {
    List<Widget> slideWidgets = [];
    for (int i = 0; i < presentation.slides.length; i++) {
      List<Widget> tempValue = await compute(getSlideDetails, {
        'slide': presentation.slides[i],
        'screenWidth': screenWidth,
        'presentationSize': _slideSizes[presentation.hashCode],
      });
      slideWidgets.addAll(tempValue);
    }
    return [Column(children: slideWidgets)];
  }

  static List<Widget> getSlideDetails(Map<String, dynamic> params) {
    Slide slide = params['slide'];
    double screenWidth = params['screenWidth'];
    Size? presSize = params['presentationSize'];
    
    List<Widget> tempShapes = [];
    double maxWidth = presSize?.width ?? 960;
    double maxHeight = presSize?.height ?? 540;
    const double divisionFactor = 12700;

    for (var box in slide.presentationTextBoxes) {
       double dx = box.offset.dx / divisionFactor;
       double dy = box.offset.dy / divisionFactor;
       double w = box.size.width / divisionFactor;
       double h = box.size.height / divisionFactor;
       
       List<Widget> paras = [];
       for (var para in box.presentationParas) {
         paras.add(RichText(text: TextSpan(children: para.textSpans.map((s) => TextSpan(text: s.text, style: TextStyle(fontSize: s.fontSize, color: Colors.black))).toList())));
       }
       
       tempShapes.add(Positioned(
         top: dy, left: dx,
         child: SizedBox(height: h != 0 ? h : null, width: w != 0 ? w : null, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: paras)),
       ));
    }
    
    for (var shape in slide.presentationShapes) {
       double dx = shape.offset.dx / divisionFactor;
       double dy = shape.offset.dy / divisionFactor;
       double w = shape.size.width / divisionFactor;
       double h = shape.size.height / divisionFactor;
       
       if (shape.text.startsWith("IMG|")) {
         String path = shape.text.substring(4);
         tempShapes.add(Positioned(
           top: dy, left: dx,
           child: Image.file(File(path), width: w, height: h, fit: BoxFit.fill),
         ));
       } else {
         tempShapes.add(Positioned(
           top: dy, left: dx,
           child: Container(
             decoration: BoxDecoration(border: Border.all(color: Colors.blue.withOpacity(0.05))),
             height: h, width: w,
           )
         ));
       }
    }

    return [Container(
      constraints: BoxConstraints(maxWidth: screenWidth),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        image: slide.backgroundImagePath.isNotEmpty 
          ? DecorationImage(image: FileImage(File(slide.backgroundImagePath)), fit: BoxFit.fill) 
          : null,
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(width: maxWidth, height: maxHeight, child: Stack(children: tempShapes)),
      ),
    )];
  }
}
