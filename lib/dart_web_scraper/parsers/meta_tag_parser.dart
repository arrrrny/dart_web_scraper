import 'package:dart_web_scraper/common/utils/data_extraction.dart';
import 'package:html/dom.dart';
import 'package:dart_web_scraper/dart_web_scraper.dart';

Data? metaTagParser({
  required Parser parser,
  required Data parentData,
  required bool debug,
}) {
  printLog("----------------------------------", debug, color: LogColor.yellow);
  printLog("ID: ${parser.id} Parser: Meta Tag", debug, color: LogColor.cyan);
  List<Element>? element = getElementObject(parentData);
  if (element == null || element.isEmpty) {
    printLog(
      "Meta Tag Parser: Element not found!",
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

  List<Element> metaTags = document.querySelectorAll('meta');
  if (metaTags.isNotEmpty) {
    final Map<String, dynamic> metaData = {};

    for (final tag in metaTags) {
      String? name = tag.attributes['name'] ?? tag.attributes['property'];
      if (name?.startsWith('og:') == true) {
        name = name!.substring(3);
      }
      final content = tag.attributes['content'];
      if (name != null && content != null) {
        metaData[name] = content;
      }
    }

    return Data(parentData.url, metaData);
  }
  printLog(
    "Meta Tag Parser: No data found!",
    debug,
    color: LogColor.orange,
  );
  return null;
}
