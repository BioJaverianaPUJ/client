import 'api_client.dart';

class CatalogPage {
  const CatalogPage(this.items, this.hasNext);
  final List<Map<String, dynamic>> items;
  final bool hasNext;
}

class CatalogService {
  const CatalogService(this.api);
  final ApiClient api;
  Future<CatalogPage> page(String resource, int page) async {
    assert(resource == 'species' || resource == 'specimens');
    final json = await api.get('/$resource?page=$page&size=100');
    final entries = (json['content'] as List).cast<Map<String, dynamic>>();
    final pagination = json['pagination'] as Map<String, dynamic>;
    final total = pagination['totalPages'] as int;
    return CatalogPage(entries, page + 1 < total);
  }

  Future<Map<String, dynamic>> species(String id) =>
      api.get('/species/${Uri.encodeComponent(id)}');
}
