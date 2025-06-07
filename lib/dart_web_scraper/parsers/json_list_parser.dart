import 'dart:convert';
import 'package:dart_web_scraper/common/utils/data_extraction.dart';
import 'package:html/dom.dart';
import 'package:dart_web_scraper/dart_web_scraper.dart';

Data? jsonListParser({
  required Parser parser,
  required Data parentData,
  required bool debug,
}) {
  printLog("----------------------------------", debug, color: LogColor.yellow);
  printLog("ID: ${parser.id} Parser: JSON List", debug, color: LogColor.cyan);
  List<Element>? element = getElementObject(parentData);
  if (element == null || element.isEmpty) {
    printLog(
      "JSON List Parser: Element not found!",
      debug,
      color: LogColor.red,
    );
    return null;
  }
  Element document;
  if (element.length == 1) {
    document = element[0];
  } else {
    throw UnimplementedError("Multiple elements not supported");
  }

  List<Map<String, dynamic>> results = [];

  List<Element> selector = document
      .querySelectorAll('script')
      .where((tag) => tag.attributes['type'] != 'application/ld+json')
      .toList();
  if (selector.isNotEmpty) {
    results = _extractFromElements(selector);
    return Data(parentData.url, results);
  }
  printLog(
    "JSON List Parser: No data found!",
    debug,
    color: LogColor.orange,
  );
  return null;
}

List<Map<String, dynamic>> _extractFromElements(List<Element> elements) {
  RegExp jsonRegExp = RegExp(
    r'\{.*?\}',
    dotAll: true,
  );
  List<Map<String, dynamic>> jsonDataList = [];

  for (var element in elements) {
    String elementContent = element.text.trim();
    List<String> jsonStrings = extractJsonStrings(elementContent);
    for (var jsonString in jsonStrings) {
      try {
        Map<String, dynamic> jsonData = json.decode(jsonString);
        jsonDataList.add(jsonData);
      } catch (e) {
        continue;
      }
    }
    try {
      _extractAndAddJsonData(elementContent, jsonDataList);
    } catch (e) {
      Iterable<RegExpMatch> matches = jsonRegExp.allMatches(elementContent);
      for (var match in matches) {
        String possibleJson = match.group(0)!;
        try {
          _extractAndAddJsonData(possibleJson, jsonDataList);
        } catch (e) {
          continue;
        }
      }
    }
  }

  return jsonDataList;
}

void _extractAndAddJsonData(
    String text, List<Map<String, dynamic>> jsonDataList) {
  var decodedJson = json.decode(text);
  if (decodedJson is Map<String, dynamic> && decodedJson.isNotEmpty) {
    jsonDataList.add(decodedJson);
  }
}

List<String> extractJsonStrings(String scriptContent) {
  // Regular expression to match JSON.parse("...") and capture the JSON string
  final RegExp jsonParseRegex = RegExp(r'JSON\.parse\("((?:\\.|[^"\\])*)"\)');

  Iterable<RegExpMatch> matches = jsonParseRegex.allMatches(scriptContent);
  List<String> jsonStrings = [];

  for (var match in matches) {
    if (match.groupCount >= 1) {
      String escapedJson = match.group(1)!;

      // Unescape the JSON string
      String unescapedJson = _unescapeString(escapedJson);

      jsonStrings.add(unescapedJson);
    }
  }
  return jsonStrings;
}

String _unescapeString(String escaped) {
  return escaped.replaceAll(r'\"', '"').replaceAll(r'\\', '\\');
}
