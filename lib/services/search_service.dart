import 'package:duckduckgo_search/duckduckgo_search.dart' as ddg;

class SearchResultItem {
  final String title;
  final String snippet;
  final String url;

  SearchResultItem({
    required this.title,
    required this.snippet,
    required this.url,
  });
}

class SearchService {
  final ddg.DuckDuckGoSearch _ddg = ddg.DuckDuckGoSearch();

  /// Search the web using DuckDuckGo.
  Future<List<SearchResultItem>> search(String query,
      {int maxResults = 3}) async {
    try {
      final results = await _ddg.text(query, maxResults: maxResults);
      return results
          .map((r) => SearchResultItem(
                title: r.title,
                snippet: r.body,
                url: r.link,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Search for recent news using DuckDuckGo.
  Future<List<SearchResultItem>> searchNews(String query,
      {int maxResults = 3}) async {
    try {
      final results = await _ddg.news(
        query,
        region: 'nl-nl',
        timelimit: 'd',
        maxResults: maxResults,
      );
      return results
          .map((r) => SearchResultItem(
                title: r.title,
                snippet: r.body,
                url: r.url,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Format search results as text.
  String formatResults(List<SearchResultItem> results, {String label = 'Zoekresultaten'}) {
    if (results.isEmpty) {
      return 'Geen resultaten gevonden.';
    }

    final buffer = StringBuffer('$label:\n');
    for (var i = 0; i < results.length; i++) {
      buffer.writeln('${i + 1}. ${results[i].title}');
      buffer.writeln('   ${results[i].snippet}');
    }
    return buffer.toString();
  }
}
