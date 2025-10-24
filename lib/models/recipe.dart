class Recipe {
  final String id;
  final String label;
  final String image;
  final String source;
  final String url;
  final String cuisineType;
  final double calories;
  final int yield;
  final List<String> dietLabels;
  final List<Ingredient> ingredients;
  final List<String> instructions;

  Recipe({
    required this.id,
    required this.label,
    required this.image,
    required this.source,
    required this.url,
    required this.cuisineType,
    required this.calories,
    required this.yield,
    required this.dietLabels,
    required this.ingredients,
    required this.instructions,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<Ingredient> parseIngredients() {
      List<Ingredient> ingredients = [];
      
      // TheMealDB tiene ingredientes en campos como strIngredient1, strIngredient2, etc.
      for (int i = 1; i <= 20; i++) {
        String? ingredient = json['strIngredient$i'];
        String? measure = json['strMeasure$i'];
        
        if (ingredient != null && ingredient.isNotEmpty) {
          ingredients.add(
            Ingredient(
              label: ingredient,
              weight: 0.0,
              foodId: ingredient,
              measure: measure ?? '',
            ),
          );
        }
      }
      
      return ingredients;
    }

    return Recipe(
      id: json['idMeal'] ?? 'unknown',
      label: json['strMeal'] ?? 'Sin nombre',
      image: json['strMealThumb'] ?? '',
      source: json['strSource'] ?? 'TheMealDB',
      url: json['strSource'] ?? '',
      cuisineType: json['strArea'] ?? 'Desconocida',
      calories: 0.0, // TheMealDB no proporciona calorías
      yield: 1,
      dietLabels: json['strTags'] != null 
          ? (json['strTags'] as String).split(',').map((e) => e.trim()).toList()
          : [],
      ingredients: parseIngredients(),
      instructions: json['strInstructions'] != null
          ? (json['strInstructions'] as String).split('. ')
              .where((s) => s.isNotEmpty)
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'image': image,
      'source': source,
      'url': url,
      'cuisineType': cuisineType,
      'calories': calories,
      'yield': yield,
      'dietLabels': dietLabels,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Ingredient {
  final String label;
  final double weight;
  final String foodId;
  final String measure;

  Ingredient({
    required this.label,
    required this.weight,
    required this.foodId,
    this.measure = '',
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      label: json['food']['label'] ?? 'Ingrediente',
      weight: (json['weight'] ?? 0).toDouble(),
      foodId: json['food']['foodId'] ?? '',
    );
  }
}