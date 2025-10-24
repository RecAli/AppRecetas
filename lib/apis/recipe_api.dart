import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class RecipeApi {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';
  static final Map<String, List<Recipe>> _cache = {};
  static final Map<String, List<String>> _categoriesCache = {};

  static const List<String> _letters = [
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
    'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
  ];

  /// Obtiene recetas haciendo búsquedas concurrentes por letra
  Future<List<Recipe>> fetchRecipes() async {
    try {
      // Hacemos múltiples peticiones concurrentes
      List<Future<List<Recipe>>> futures =
          _letters.map((letter) => _fetchByLetter(letter)).toList();

      // Esperamos que terminen todas
      final results = await Future.wait(futures);

      // Combinamos todas las listas en una sola
      final allRecipes = results.expand((recipes) => recipes).toList();

      // Limitamos a 100 recetas
      return allRecipes.length > 100 ? allRecipes.sublist(0, 100) : allRecipes;
    } catch (e) {
      throw Exception('Error al obtener recetas: $e');
    }
  }

  /// Busca recetas por nombre
  Future<List<Recipe>> searchRecipes(String query, {String? cuisineType, String? health}) async {
    if (query.isEmpty) {
      throw Exception('Debes ingresar un término de búsqueda');
    }

    String cacheKey = query;

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isNotEmpty) {
      return _cache[cacheKey]!;
    }

    try {
      // Búsqueda por nombre: s=nombre
      final url = '$_baseUrl/search.php?s=${Uri.encodeComponent(query)}';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw Exception('Tiempo de conexión agotado. Intenta de nuevo.'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> meals = data['meals'] ?? [];

        List<Recipe> recipes = meals
            .map((json) {
              try {
                return Recipe.fromJson(json);
              } catch (e) {
                return null;
              }
            })
            .whereType<Recipe>()
            .toList();

        _cache[cacheKey] = recipes;
        return recipes;
      } else {
        throw Exception('Error al obtener recetas (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Obtiene recetas que inician con una letra específica
  Future<List<Recipe>> _fetchByLetter(String letter) async {
    try {
      // f=primera letra
      final url = '$_baseUrl/search.php?f=$letter';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> meals = data['meals'] ?? [];

        return meals
            .map((json) {
              try {
                return Recipe.fromJson(json);
              } catch (e) {
                return null;
              }
            })
            .whereType<Recipe>()
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Obtiene todas las categorías disponibles
  Future<List<String>> getCategories() async {
    if (_categoriesCache.containsKey('categories')) {
      return _categoriesCache['categories']!;
    }

    try {
      final url = '$_baseUrl/categories.php';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> categories = data['categories'] ?? [];

        List<String> categoryNames = categories
            .map((cat) => cat['strCategory'] as String)
            .toList();

        _categoriesCache['categories'] = categoryNames;
        return categoryNames;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Busca recetas por categoría: c=categoria
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    String cacheKey = 'category-$category';

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isNotEmpty) {
      return _cache[cacheKey]!;
    }

    try {
      final url = '$_baseUrl/filter.php?c=${Uri.encodeComponent(category)}';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> meals = data['meals'] ?? [];

        List<Recipe> recipes = meals
            .map((meal) {
              try {
                return Recipe(
                  id: meal['idMeal'] ?? 'unknown',
                  label: meal['strMeal'] ?? 'Sin nombre',
                  image: meal['strMealThumb'] ?? '',
                  source: 'TheMealDB',
                  url: '',
                  cuisineType: category,
                  calories: 0.0,
                  yield: 1,
                  dietLabels: [],
                  ingredients: [],
                  instructions: [],
                );
              } catch (e) {
                return null;
              }
            })
            .whereType<Recipe>()
            .toList();

        _cache[cacheKey] = recipes;
        return recipes;
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Obtiene receta por ID para obtener detalles completos
  Future<Recipe?> getMealById(String id) async {
    try {
      final url = '$_baseUrl/lookup.php?i=$id';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> meals = data['meals'] ?? [];

        if (meals.isNotEmpty) {
          return Recipe.fromJson(meals[0]);
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Obtiene recetas por área/país: a=area
  Future<List<Recipe>> getRecipesByArea(String area) async {
    String cacheKey = 'area-$area';

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isNotEmpty) {
      return _cache[cacheKey]!;
    }

    try {
      final url = '$_baseUrl/filter.php?a=${Uri.encodeComponent(area)}';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> meals = data['meals'] ?? [];

        List<Recipe> recipes = meals
            .map((meal) {
              try {
                return Recipe(
                  id: meal['idMeal'] ?? 'unknown',
                  label: meal['strMeal'] ?? 'Sin nombre',
                  image: meal['strMealThumb'] ?? '',
                  source: 'TheMealDB',
                  url: '',
                  cuisineType: area,
                  calories: 0.0,
                  yield: 1,
                  dietLabels: [],
                  ingredients: [],
                  instructions: [],
                );
              } catch (e) {
                return null;
              }
            })
            .whereType<Recipe>()
            .toList();

        _cache[cacheKey] = recipes;
        return recipes;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  void clearCache() {
    _cache.clear();
  }

  void clearCacheForQuery(String query) {
    _cache.removeWhere((key, value) => key.startsWith(query));
  }
}