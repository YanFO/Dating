class AuthUser {
  final String id;
  final String email;
  final String? name;
  final String? image;

  const AuthUser({
    required this.id,
    required this.email,
    this.name,
    this.image,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        image: json['image'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'image': image,
      };
}

class AuthState {
  final AuthUser? user;
  final String? sessionToken;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.sessionToken,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && sessionToken != null;

  AuthState copyWith({
    AuthUser? user,
    String? sessionToken,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearToken = false,
    bool clearError = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        sessionToken: clearToken ? null : (sessionToken ?? this.sessionToken),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}
