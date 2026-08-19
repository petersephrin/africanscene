import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../firebase_options.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Sign in with email & password and retrieve Firestore profile
  Future<UserModel?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (credential.user == null) return null;

    final doc = await _firestore.collection('users').doc(credential.user!.uid).get();

    if (!doc.exists) {
      // If user document does not exist yet (e.g. initial admin), create baseline document
      final newUser = UserModel(
        id: credential.user!.uid,
        email: credential.user!.email ?? email,
        firstName: '',
        lastName: '',
        name: credential.user!.displayName ?? email.split('@')[0],
        role: email.toLowerCase().contains('admin') ? UserRole.superAdmin : UserRole.researcher,
        userType: email.toLowerCase().contains('admin') ? 'admin' : 'researcher',
        status: 'active',
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(credential.user!.uid).set(newUser.toMap());
      return newUser;
    }

    return UserModel.fromFirestore(doc);
  }

  /// Send password reset link to user email
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Update password of currently logged in user
  Future<void> updatePassword(String newPassword) async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updatePassword(newPassword);
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Fetch user profile from Firestore by UID
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(
      user.toMap(),
      SetOptions(merge: true),
    );
  }

  /// Create a new user (Staff / Researcher / Teacher / Admin) without logging out the active Admin.
  /// Uses an isolated secondary Firebase App instance.
  Future<UserModel> createUserByAdmin({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
    required String userType,
    String? phone,
    String? department,
    String? specialization,
    List<String> schoolIds = const [],
  }) async {
    FirebaseApp? secondaryApp;
    try {
      final appName = 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final newUid = cred.user!.uid;
      final fullName = '$firstName $lastName'.trim();

      final newUser = UserModel(
        id: newUid,
        email: email.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        name: fullName.isNotEmpty ? fullName : email.split('@')[0],
        phone: phone,
        role: role,
        userType: userType,
        department: department,
        specialization: specialization,
        schoolIds: schoolIds,
        status: 'active',
        createdAt: DateTime.now(),
      );

      // Save user record to main Firestore collection
      await _firestore.collection('users').doc(newUid).set(newUser.toMap());

      await secondaryAuth.signOut();
      return newUser;
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }
}
