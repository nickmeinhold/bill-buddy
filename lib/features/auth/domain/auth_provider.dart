import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Sign in with Google (for Android/Web)
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // Use Firebase Auth's signInWithPopup for web
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      return await _auth.signInWithPopup(googleProvider);
    }

    // Use google_sign_in package for mobile
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Google sign in was cancelled');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null && idToken == null) {
      throw Exception('Failed to get Google authentication tokens');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  /// Sign in with Apple (for iOS/macOS)
  Future<UserCredential> signInWithApple() async {
    // Generate a random nonce for security
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    // Debug logging
    print('Apple credential received:');
    print('  userIdentifier: ${appleCredential.userIdentifier}');
    print('  email: ${appleCredential.email}');
    print('  identityToken length: ${appleCredential.identityToken?.length}');
    print('  authorizationCode length: ${appleCredential.authorizationCode?.length}');

    // Decode JWT to see the bundle ID (aud claim)
    if (appleCredential.identityToken != null) {
      final parts = appleCredential.identityToken!.split('.');
      if (parts.length >= 2) {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        print('  JWT payload: $payload');
      }
    }

    // Check if we got a valid identity token
    final identityToken = appleCredential.identityToken;
    if (identityToken == null) {
      throw Exception('Apple Sign In failed: No identity token received');
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: identityToken,
      rawNonce: rawNonce,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Update display name if provided (Apple only sends it on first sign-in)
    if (appleCredential.givenName != null || appleCredential.familyName != null) {
      final displayName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((n) => n != null).join(' ');

      if (displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
      }
    }

    return userCredential;
  }

  /// Generate a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// SHA256 hash of a string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
