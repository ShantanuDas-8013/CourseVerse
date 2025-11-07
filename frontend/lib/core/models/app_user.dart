class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final List<String> roles;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.roles,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'roles': roles,
    };
  }
}
