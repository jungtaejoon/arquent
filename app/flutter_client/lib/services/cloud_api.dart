import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/recipe_models.dart';

class CloudApi {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );

  CloudApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? defaultBaseUrl;

  final http.Client _client;
  final String baseUrl;

  Future<void> publishDemoRecipe() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/marketplace/publish-demo'),
      headers: {'content-type': 'application/json'},
      body: '{}',
    );
    if (response.statusCode >= 400) {
      throw Exception('publish demo failed: ${response.body}');
    }
  }

  Future<void> publishRecipe({
    required String id,
    required String manifest,
    required String flow,
    required String signature,
    required String publicKey,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/marketplace/publish'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'manifest': manifest,
        'flow': flow,
        'signature': signature,
        'publicKey': publicKey,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('publish failed: ${response.body}');
    }
  }

  Future<void> publishLocalRecipe({
    required String id,
    required String manifest,
    required String flow,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/marketplace/publish-local'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'manifest': manifest,
        'flow': flow,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('publish local failed: ${response.body}');
    }
  }

  Future<List<CloudRecipeSummary>> fetchMarketplaceRecipes() async {
    final response = await _client.get(Uri.parse('$baseUrl/marketplace/recipes'));
    if (response.statusCode >= 400) {
      throw Exception('fetch recipes failed: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final recipes = (json['recipes'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(CloudRecipeSummary.fromJson)
        .toList();
    return recipes;
  }

  Future<CloudRecipePackage> fetchRecipePackage(String id) async {
    final response = await _client.get(Uri.parse('$baseUrl/marketplace/package/$id'));
    if (response.statusCode >= 400) {
      throw Exception('fetch package failed: ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return CloudRecipePackage.fromJson(json);
  }
}
