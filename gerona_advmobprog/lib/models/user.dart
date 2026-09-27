// Enhancement 2 (DummyJSON vs Firebase Auth):
// Tracks which backend authenticated the current session so the Profile
// screen and UserService know whether to call the real FirebaseAuth APIs
// or simulate the change locally against the DummyJSON demo account.
enum LoginType {
  dummyJson,
  firebase;

  String get storageValue => name;

  static LoginType fromStorage(String? value) {
    return LoginType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => LoginType.dummyJson,
    );
  }
}

// LAB_ACT4 ENHANCEMENT 3:
// The User model defines the shape of the authenticated user data, whether
// sourced from the DummyJSON /auth/login (or /users/add) endpoints, or built
// locally from a Firebase Auth account. It is cached locally via UserService.
class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final String accessToken;
  final String refreshToken;
  final LoginType loginType;
  // Extra signup fields collected by the signup form. DummyJSON's user
  // schema supports `age`, but has no dedicated contact-number field, and
  // Firebase Auth accounts have neither, so both are simply cached locally.
  final String uid;
  final int age;
  final String contactNo;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    required this.accessToken,
    required this.refreshToken,
    this.loginType = LoginType.dummyJson,
    this.age = 0,
    this.contactNo = '',
    this.uid = '',
  });

  // Convenience getter used across the profile UI.
  String get fullName => '$firstName $lastName'.trim();
  
  // Enhancement 2 (DummyJSON vs Firebase Auth):
  // Firebase accounts have no numeric DummyJSON id, so `id` is 0 for them.
  // DummyJSON's cart endpoints need a real numeric user id, so Firebase
  // sessions fall back to DummyJSON's demo user #1 whenever they talk to
  // the cart API. This is what CartProvider/CartScreen should use instead
  // of `id` directly.
  int get cartUserId => id > 0 ? id : 1;

  String get localCartKey => 'local_cart_${uid.isNotEmpty ? uid : email}';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      gender: json['gender'] ?? '',
      image: json['image'] ?? '',
      // DummyJSON's /auth/login response uses `accessToken`, but some versions of the API return `token` instead, so fall back to that.
      accessToken: json['accessToken'] ?? json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      loginType: LoginType.fromStorage(json['loginType'] as String?),
      age: json['age'] ?? 0,
      contactNo: json['contactNo'] ?? '',
      uid: json['uid'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'image': image,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'loginType': loginType.storageValue,
      'age': age,
      'contactNo': contactNo,
      'uid': uid,
    };
  }

  User copyWith({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender,
      image: image,
      accessToken: accessToken,
      refreshToken: refreshToken,
      loginType: loginType,
      age: age,
      contactNo: contactNo,
      uid: uid,
    );
  }
}
