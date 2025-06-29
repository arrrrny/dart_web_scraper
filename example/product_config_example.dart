import 'dart:convert';
import 'package:dart_web_scraper/dart_web_scraper.dart';
import 'package:html/parser.dart';

/// Config for a product site using SKU slot injection
Map<String, List<Config>> configMap = {
  'shop.example.com': productConfig,
};

List<Config> productConfig = [
  Config(
    usePassedUserAgent: true,
    parsers: {
      "main": [
        // Parse the product block
        Parser(
          id: "products",
          parent: ["_root"],
          type: ParserType.element,
          selector: [
            ".product",
          ],
          multiple: true,
        ),

        // Parse the product name
        Parser(
          id: "attributes",
          parent: ["products"],
          type: ParserType.text,
          selector: [
            "span",
          ],
          multiple: true,
          optional: Optional.any(regex: r'^(?!.*555).+$'),
        ),
      ],
    },
    urlTargets: [
      UrlTarget(
        name: 'main',
        where: ["/"],
      ),
    ],
  ),
];

void main() async {
  // Simulated HTML for demonstration
  final html = '''
    <div class="product">
      <span class="product-sku">SKU-55555</span>
      <span class="product-name">aaaa Pro</span>
    </div>
    <div class="product">
      <span class="product-sku">SKU-88888</span>
      <span class="product-name">Widget Mini</span>
    </div>
  ''';
  final document = parse(html);

  // Simulate the root data as if scraped from the site

  // Initialize the parser
  final webScraper = WebScraper();

  // Parse using the config
  final result = await webScraper.scrape(
    html: document,
    url: Uri.parse('https://shop.example.com/products'),
    configMap: configMap,
    configIndex: 0,
    debug: true,
    concurrentParsing: false,
  );

  print(jsonEncode(result));
  // Expected output (structure):
  // {
  //   "products": [
  //     {
  //       "sku": "SKU-55555",
  //       "name": "Widget Pro",
  //       "productUrl": "https://shop.example.com/item/SKU-55555"
  //     },
  //     {
  //       "sku": "SKU-88888",
  //       "name": "Widget Mini",
  //       "productUrl": "https://shop.example.com/item/SKU-88888"
  //     }
  //   ],
  //   "url": "https://shop.example.com/products"
  // }
}
