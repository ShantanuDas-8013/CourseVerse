import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';

final _logger = Logger('AuthService');

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream to listen for auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // --- Email/Password Sign-In ---
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle errors (e.g., user-not-found, wrong-password)
      _logger.warning(e.message ?? 'FirebaseAuthException');
      return null;
    }
  }

  // --- Google Sign-In ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // 2. Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create a new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _logger.warning(e.message ?? 'FirebaseAuthException (Google sign-in)');
      return null;
    }
  }

  // --- Sign-Up (We need this for the "Sign Up" button) ---
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      // NOTE: In a real app, you'd call your Spring Boot backend here
      // to create the user document in Firestore.
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.warning(e.message ?? 'FirebaseAuthException (sign-up)');
      return null;
    }
  }

  // --- Sign-Out ---
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
