import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUpWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<UserCredential> signInWithGoogle() async {
  final googleProvider = GoogleAuthProvider();

  if (kIsWeb) {
    return _auth.signInWithPopup(googleProvider);
  } else {
    await GoogleSignIn.instance.initialize();
    final googleUser = await GoogleSignIn.instance.authenticate();

    final auth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }
}
  Future<void> signOut() => _auth.signOut();
}