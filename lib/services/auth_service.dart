import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Web client ID is required on Android to obtain idToken for Firebase Auth
    serverClientId: '913378360413-4i98i0fdj98gn8r634hv27c9q2hmupk5.apps.googleusercontent.com',
  );
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Streams ──────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // ── Email / Password Sign Up ──────────────────
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user!.updateDisplayName(displayName);
      await _createParentAccount(cred.user!, displayName);
      return AuthResult.success(cred.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseError(e));
    }
  }

  // ── Email / Password Sign In ──────────────────
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.success(cred.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseError(e));
    }
  }

  // ── Google SSO ───────────────────────────────
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return AuthResult.error('Sign-in cancelled');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);

      // Create account doc if first time
      final doc = await _db.collection('parents').doc(cred.user!.uid).get();
      if (!doc.exists) {
        await _createParentAccount(cred.user!, cred.user!.displayName ?? '');
      }

      return AuthResult.success(cred.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  // ── Password Reset ────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Sign Out ──────────────────────────────────
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  // ── Create parent Firestore doc ───────────────
  Future<void> _createParentAccount(User user, String displayName) async {
    await _db.collection('parents').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName,
      'photoUrl': user.photoURL ?? '',
      'subscription': 'trial',
      'trialStartedAt': FieldValue.serverTimestamp(),
      'trialEndsAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 7)),
      ),
      'childIds': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Helpers ───────────────────────────────────
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }
}

class AuthResult {
  final User? user;
  final String? error;
  bool get isSuccess => user != null;

  AuthResult.success(this.user) : error = null;
  AuthResult.error(this.error) : user = null;
}
