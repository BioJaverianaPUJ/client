import 'dart:convert';
import 'package:http/http.dart' as http;

class ReferenceImage {
  const ReferenceImage(this.url, this.credit, this.license, this.source);
  final String url, credit, license, source;
}

class ReferenceImages {
  ReferenceImages({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    final r = await _client
        .get(Uri.https('api.gbif.org', path, query))
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) {
      throw const FormatException('GBIF no está disponible');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<ReferenceImage>> find(String scientificName) async {
    final match = await _get('/v1/species/match', {
      'name': scientificName,
      'strict': 'true',
    });
    if (match['matchType'] != 'EXACT' || match['usageKey'] == null) return [];
    final data = await _get('/v1/occurrence/search', {
      'taxonKey': '${match['usageKey']}',
      'mediaType': 'StillImage',
      'limit': '10',
    });
    final images = <ReferenceImage>[];
    final seen = <String>{};
    for (final occurrence in data['results'] as List? ?? []) {
      for (final media in occurrence['media'] as List? ?? []) {
        final url = media['identifier'] as String? ?? '';
        final license = media['license'] as String? ?? '';
        if (!url.startsWith('https://') ||
            !seen.add(url) ||
            !RegExp(
              r'^https?://creativecommons\.org/(licenses/by(-sa)?/|publicdomain/zero/)',
            ).hasMatch(license)) {
          continue;
        }
        images.add(
          ReferenceImage(
            url,
            '${media['creator'] ?? media['rightsHolder'] ?? media['publisher'] ?? 'Autor no indicado'} · GBIF',
            license,
            'https://www.gbif.org/occurrence/${occurrence['key']}',
          ),
        );
        if (images.length == 5) return images;
      }
    }
    return images;
  }

  void close() => _client.close();
}
