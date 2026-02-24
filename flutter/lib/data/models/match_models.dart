class MatchRecord {
  final String matchId;
  final String name;
  final String? contextTag;
  final String status;
  final String createdAt;
  final String updatedAt;

  const MatchRecord({
    required this.matchId,
    required this.name,
    this.contextTag,
    this.status = 'active',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory MatchRecord.fromJson(Map<String, dynamic> json) {
    return MatchRecord(
      matchId: json['match_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      contextTag: json['context_tag'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class MemoryProfile {
  final String memoryId;
  final String userId;
  final String matchId;
  // 1. 基本資訊
  final String? birthday;
  final List<dynamic> anniversaries;
  final String? mbtiOrZodiac;
  final List<String> routine;
  // 2. 飲食偏好
  final List<String> favoriteFood;
  final List<String> favoriteRestaurant;
  final List<String> dislikedFood;
  final List<String> dietaryRestrictions;
  final List<String> beverageCustomization;
  // 3. 地點與休閒
  final List<String> favoritePlaces;
  final List<String> travelWishlist;
  final List<String> hobbies;
  final List<String> entertainmentTastes;
  // 4. 情感地雷
  final List<String> landmines;
  final List<String> petPeeves;
  final List<String> soothingMethods;
  final List<String> loveLanguages;
  // 5. 送禮
  final List<String> wishlist;
  final List<String> favoriteBrands;
  final List<String> aestheticPreference;
  // 6. 其他
  final List<String> otherNotes;

  const MemoryProfile({
    this.memoryId = '',
    this.userId = '',
    this.matchId = '',
    this.birthday,
    this.anniversaries = const [],
    this.mbtiOrZodiac,
    this.routine = const [],
    this.favoriteFood = const [],
    this.favoriteRestaurant = const [],
    this.dislikedFood = const [],
    this.dietaryRestrictions = const [],
    this.beverageCustomization = const [],
    this.favoritePlaces = const [],
    this.travelWishlist = const [],
    this.hobbies = const [],
    this.entertainmentTastes = const [],
    this.landmines = const [],
    this.petPeeves = const [],
    this.soothingMethods = const [],
    this.loveLanguages = const [],
    this.wishlist = const [],
    this.favoriteBrands = const [],
    this.aestheticPreference = const [],
    this.otherNotes = const [],
  });

  bool get isEmpty =>
      birthday == null &&
      anniversaries.isEmpty &&
      mbtiOrZodiac == null &&
      routine.isEmpty &&
      favoriteFood.isEmpty &&
      favoriteRestaurant.isEmpty &&
      dislikedFood.isEmpty &&
      dietaryRestrictions.isEmpty &&
      beverageCustomization.isEmpty &&
      favoritePlaces.isEmpty &&
      travelWishlist.isEmpty &&
      hobbies.isEmpty &&
      entertainmentTastes.isEmpty &&
      landmines.isEmpty &&
      petPeeves.isEmpty &&
      soothingMethods.isEmpty &&
      loveLanguages.isEmpty &&
      wishlist.isEmpty &&
      favoriteBrands.isEmpty &&
      aestheticPreference.isEmpty &&
      otherNotes.isEmpty;

  static List<String> _toStringList(dynamic val) {
    if (val is List) return val.map((e) => e.toString()).toList();
    return [];
  }

  factory MemoryProfile.fromJson(Map<String, dynamic> json) {
    return MemoryProfile(
      memoryId: json['memory_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      matchId: json['match_id'] as String? ?? '',
      birthday: json['birthday'] as String?,
      anniversaries: json['anniversaries'] as List<dynamic>? ?? [],
      mbtiOrZodiac: json['mbti_or_zodiac'] as String?,
      routine: _toStringList(json['routine']),
      favoriteFood: _toStringList(json['favorite_food']),
      favoriteRestaurant: _toStringList(json['favorite_restaurant']),
      dislikedFood: _toStringList(json['disliked_food']),
      dietaryRestrictions: _toStringList(json['dietary_restrictions']),
      beverageCustomization: _toStringList(json['beverage_customization']),
      favoritePlaces: _toStringList(json['favorite_places']),
      travelWishlist: _toStringList(json['travel_wishlist']),
      hobbies: _toStringList(json['hobbies']),
      entertainmentTastes: _toStringList(json['entertainment_tastes']),
      landmines: _toStringList(json['landmines']),
      petPeeves: _toStringList(json['pet_peeves']),
      soothingMethods: _toStringList(json['soothing_methods']),
      loveLanguages: _toStringList(json['love_languages']),
      wishlist: _toStringList(json['wishlist']),
      favoriteBrands: _toStringList(json['favorite_brands']),
      aestheticPreference: _toStringList(json['aesthetic_preference']),
      otherNotes: _toStringList(json['other_notes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'birthday': birthday,
      'anniversaries': anniversaries,
      'mbti_or_zodiac': mbtiOrZodiac,
      'routine': routine,
      'favorite_food': favoriteFood,
      'favorite_restaurant': favoriteRestaurant,
      'disliked_food': dislikedFood,
      'dietary_restrictions': dietaryRestrictions,
      'beverage_customization': beverageCustomization,
      'favorite_places': favoritePlaces,
      'travel_wishlist': travelWishlist,
      'hobbies': hobbies,
      'entertainment_tastes': entertainmentTastes,
      'landmines': landmines,
      'pet_peeves': petPeeves,
      'soothing_methods': soothingMethods,
      'love_languages': loveLanguages,
      'wishlist': wishlist,
      'favorite_brands': favoriteBrands,
      'aesthetic_preference': aestheticPreference,
      'other_notes': otherNotes,
    };
  }
}
