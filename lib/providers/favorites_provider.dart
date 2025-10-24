import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteIds = {};
  final Map<String, Recipe> _recipes = {};
  SharedPreferences? _prefs;

  Set<String> get favoriteIds => _favoriteIds;
  Map<String, Recipe> get recipes => _recipes;

  List<Recipe> get favorites =>
      _favoriteIds.map((id) => _recipes[id]).whereType<Recipe>().toList();

  int get favoritesCount => _favoriteIds.length;

  FavoritesProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    _prefs = await SharedPreferences.getInstance();
    final List<String>? saved = _prefs?.getStringList('favorites');
    if (saved != null) {
      _favoriteIds.addAll(saved);
      notifyListeners();
    }
  }

  Future<void> addFavorite(Recipe recipe) async {
    _favoriteIds.add(recipe.id);
    _recipes[recipe.id] = recipe;
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> removeFavorite(String recipeId) async {
    _favoriteIds.remove(recipeId);
    _recipes.remove(recipeId);
    await _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(String recipeId) {
    return _favoriteIds.contains(recipeId);
  }

  Future<void> toggleFavorite(Recipe recipe) async {
    if (isFavorite(recipe.id)) {
      await removeFavorite(recipe.id);
    } else {
      await addFavorite(recipe);
    }
  }

  Future<void> _saveFavorites() async {
    await _prefs?.setStringList('favorites', _favoriteIds.toList());
  }

  Future<void> clearAllFavorites() async {
    _favoriteIds.clear();
    _recipes.clear();
    await _saveFavorites();
    notifyListeners();
  }
}