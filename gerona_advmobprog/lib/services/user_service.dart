import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../models/user.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

// Enhancement 1 & 2:
// UserService is the single entry point for authentication, supporting two
// interchangeable backends selected by the user at Sign In/Sign Up
// (LoginType.dummyJson vs LoginType.firebase). 
class UserService {
  Map<String, dynamic> data = {};

  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // DummyJSON

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      data['loginType'] = LoginType.dummyJson.storageValue;
      await saveUserData(data);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  // Enhancement 2 (Sign Up UI): creates a demo account via DummyJSON's mock
  // https://dummyjson.com/users/add endpoint. DummyJSON does not persist new
  // accounts server-side, so the returned id/profile is simulated and can't
  // later be used with /auth/login — the caller is expected to route back
  // to Sign In afterwards, same as the Firebase sign-up flow.
  Future<Map<String, dynamic>> registerDummyUser({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await post(
      Uri.parse('$host/users/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      result['loginType'] = LoginType.dummyJson.storageValue;
      result['contactNo'] = contactNo;
      return result;
    } else {
      throw Exception(response.body);
    }
  }

  // Local session cache (shared by both backends)

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setString('loginType', user.loginType.storageValue);
    await prefs.setInt('age', user.age);
    await prefs.setString('contactNo', user.contactNo);
    await prefs.setString('uid', user.uid);

    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      'loginType':
          prefs.getString('loginType') ?? LoginType.dummyJson.storageValue,
      'age': prefs.getInt('age') ?? 0,
      'contactNo': prefs.getString('contactNo') ?? '',
      'uid': prefs.getString('uid') ?? '',
    };
  }

  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  Future<LoginType> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return LoginType.fromStorage(prefs.getString('loginType'));
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loginType = LoginType.fromStorage(prefs.getString('loginType'));

    // Firebase sessions are considered active as long as FirebaseAuth still
    // has a signed-in user (it persists its own session independently of
    // SharedPreferences), so check that instead of the (unused) token.
    if (loginType == LoginType.firebase) {
      return currentUser != null;
    }

    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginType = LoginType.fromStorage(prefs.getString('loginType'));

      if (loginType == LoginType.firebase) {
        await signOut();
      }

      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  // Firebase Auth

  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      await _cacheFirebaseSnapshot(credential.user!);
    }

    return credential;
  }

  Future<firebase_auth.UserCredential> createAccount({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    int age = 0,
    String contactNo = '',
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      final displayName = [
        firstName,
        lastName,
      ].where((name) => name != null && name.isNotEmpty).join(' ');

      if (displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      await _cacheFirebaseSnapshot(
        _firebaseAuth.currentUser ?? credential.user!,
        age: age,
        contactNo: contactNo,
        firstName: firstName,
        lastName: lastName,
      );
    }

    return credential;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    final loginType = await getLoginType();

    if (loginType == LoginType.firebase) {
      await currentUser!.updateDisplayName(username);
      await currentUser!.reload();
      await _cacheFirebaseSnapshot(_firebaseAuth.currentUser!);
    } else {
      // DummyJSON demo accounts have no real backend to persist this
      // change against, so we simulate it by updating the cached profile.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
    }
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final loginType = LoginType.fromStorage(prefs.getString('loginType'));

    if (loginType == LoginType.firebase) {
      final firebase_auth.AuthCredential credential = firebase_auth
          .EmailAuthProvider.credential(email: email, password: password);

      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.delete();
      await _firebaseAuth.signOut();
    }

    // Whether Firebase or a simulated DummyJSON demo account, the local
    // session cache is always cleared.
    await prefs.clear();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final loginType = await getLoginType();

    if (loginType == LoginType.firebase) {
      final firebase_auth.AuthCredential credential =
          firebase_auth.EmailAuthProvider.credential(
            email: email,
            password: currentPassword,
          );

      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(newPassword);
    }
    // DummyJSON demo accounts don't have a real password store to verify or
    // update against, so this is a no-op; the UI notifies the user that the
    // change is simulated.
  }

  // Builds/refreshes the locally-cached User snapshot from the current
  // FirebaseAuth user so Splash/Home/Profile screens can read a consistent
  // User model regardless of which backend authenticated the session.
  Future<void> _cacheFirebaseSnapshot(
    firebase_auth.User fbUser, {
    int? age,
    String? contactNo,
    String? firstName,
    String? lastName,
  }) async {
    final existing = await getUserData();
    final existingFirstName = (existing['firstName'] as String?) ?? '';
    final existingLastName = (existing['lastName'] as String?) ?? '';

    String derivedFirstName = '';
    String derivedLastName = '';
    if (existingFirstName.isEmpty) {
      final nameParts = (fbUser.displayName ?? '').trim().split(RegExp(r'\s+'));
      derivedFirstName = nameParts.isNotEmpty ? nameParts.first : '';
      derivedLastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
    }

    final snapshot = <String, dynamic>{
      'id': 0,
      'uid': fbUser.uid,
      'username': fbUser.displayName ?? existing['username'] ?? '',
      'email': fbUser.email ?? existing['email'] ?? '',
      'firstName':
          firstName ??
          (existingFirstName.isNotEmpty ? existingFirstName : derivedFirstName),
      'lastName':
          lastName ??
          (existingLastName.isNotEmpty ? existingLastName : derivedLastName),
      'gender': existing['gender'] ?? '',
      'image': fbUser.photoURL ?? existing['image'] ?? '',
      'accessToken': '',
      'refreshToken': '',
      'loginType': LoginType.firebase.storageValue,
      'age': age ?? existing['age'] ?? 0,
      'contactNo': contactNo ?? existing['contactNo'] ?? '',
    };

    await saveUserData(snapshot);
  }
}
