import 'package:dart_web_scraper/common/utils/cookie_utils.dart';
import 'package:dart_web_scraper/common/utils/http.dart';
import 'package:dart_web_scraper/common/utils/random.dart';
import 'package:dart_web_scraper/dart_web_scraper.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

/// Used for scraping HTML data from the web.
class Scraper {
  Future<Data> scrape({
    required Uri url,
    required Config config,
    Document? html,
    Map<String, String>? cookies,
    String? userAgent,
    Map<String, Object>? headers,
    Uri? proxyAPI,
    String? proxyUrlParam,
    bool debug = false,
    HttpClientType clientType = HttpClientType.browserClient,
    ConsoleClientOptions consoleClientOptions = const ConsoleClientOptions(),
    CurlClientOptions curlClientOptions = const CurlClientOptions(),
    HttpMethod method = HttpMethod.get,
    Object? body,
  }) async {
    /// Fetch target
    UrlTarget? target = fetchTarget(config.urlTargets, url);
    if (target == null) {
      printLog('Scraper: Target not found!', debug, color: LogColor.red);
      throw WebScraperError('Unsupported URL');
    } else {
      printLog('Scraper: Target found!', debug, color: LogColor.green);
    }

    /// Build headers
    printLog('Scraper: Building headers...', debug, color: LogColor.blue);
    Map<String, String> headersMerged = {
      "Accept-Language": "en-US,en",
    };

    /// User-Agent
    /// If `userAgent` is defined and config allows passing custom userAgent
    if (userAgent != null && config.usePassedUserAgent) {
      printLog(
        'Scraper: Using user-passed User-Agent...',
        debug,
        color: LogColor.blue,
      );
      headersMerged['User-Agent'] = userAgent;
    }

    /// If `userAgent` is not defined, let's generate one based on our config
    if (!headersMerged.containsKey("User-Agent")) {
      printLog(
        'Scraper: Generating random User-Agent...',
        debug,
        color: LogColor.blue,
      );
      headersMerged['User-Agent'] = randomUserAgent(config.userAgent);
    }

    /// Cookie
    /// If `cookies` variable is defined
    if (cookies != null) {
      printLog(
        'Scraper: Using user-passed cookies...',
        debug,
        color: LogColor.blue,
      );
      headersMerged['Cookie'] = mapToCookie(cookies);
    }

    if (headers != null) {
      headers.forEach((key, value) {
        headersMerged[key] = value.toString();
      });
    }

    /// Print headers
    printLog('Scraper: Headers: $headersMerged', debug, color: LogColor.blue);

    /// Clean the URL based on cleaner defined in config
    printLog('Scraper: Cleaning URL...', debug, color: LogColor.blue);
    url = cleanConfigUrl(url, target.urlCleaner);
    printLog("Scraper: Cleaned URL :) $url", debug, color: LogColor.green);

    Data dom = Data(url, "");
    printLog(
      'Scraper: Checking if target needs html...',
      debug,
      color: LogColor.blue,
    );
    if (target.needsHtml) {
      printLog('Scraper: Target needs html!!!', debug, color: LogColor.blue);
      String? requestData;
      if (config.forceFetch) {
        printLog(
          'Scraper: Forcing http request for new html!!!',
          debug,
          color: LogColor.blue,
        );
        if (method == HttpMethod.post) {
          requestData = await postRequest(
            url,
            headers: headersMerged,
            body: body,
            debug: debug,
            proxyAPI: proxyAPI,
            proxyUrlParam: proxyUrlParam,
            clientType: clientType,
            consoleClientOptions: consoleClientOptions,
            curlClientOptions: curlClientOptions,
          );
        } else {
          requestData = await getRequest(
            url,
            headers: headersMerged,
            debug: debug,
            proxyAPI: proxyAPI,
            proxyUrlParam: proxyUrlParam,
            clientType: clientType,
            consoleClientOptions: consoleClientOptions,
            curlClientOptions: curlClientOptions,
          );
        }
      } else if (config.usePassedHtml && html != null && html.hasContent()) {
        printLog(
          'Scraper: Using user-passed html :)',
          debug,
          color: LogColor.orange,
        );
        dom = Data(url, html);
      } else {
        printLog('Scraper: Fetching html...', debug, color: LogColor.blue);
        if (method == HttpMethod.post) {
          requestData = await postRequest(
            url,
            headers: headersMerged,
            body: body,
            debug: debug,
            proxyAPI: proxyAPI,
            proxyUrlParam: proxyUrlParam,
            clientType: clientType,
            consoleClientOptions: consoleClientOptions,
            curlClientOptions: curlClientOptions,
          );
        } else {
          requestData = await getRequest(
            url,
            headers: headersMerged,
            debug: debug,
            proxyAPI: proxyAPI,
            proxyUrlParam: proxyUrlParam,
            clientType: clientType,
            consoleClientOptions: consoleClientOptions,
            curlClientOptions: curlClientOptions,
          );
        }
      }
      if (dom.obj != "") {
        printLog('Scraper: HTML fetched :)', debug, color: LogColor.green);
      } else if (requestData != null) {
        printLog('Scraper: HTML fetched :)', debug, color: LogColor.green);
        dom = Data(url, parse(requestData));
      } else {
        printLog(
          'Scraper: Unable to fetch data!',
          debug,
          color: LogColor.red,
        );
        throw WebScraperError('Unable to fetch data!');
      }
    } else {
      printLog(
        'Scraper: Target does not need html. Skipping...',
        debug,
        color: LogColor.orange,
      );
    }

    printLog('Scraper: Returning data...', debug, color: LogColor.green);
    return dom;
  }
}
