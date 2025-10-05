// lib/Servicios/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // EN WEB: Usar REDIRECT en lugar de POPUP (soluciona CORS)
        print('🌐 Iniciando Google Sign-In en WEB con REDIRECT');

        final GoogleAuthProvider googleProvider = GoogleAuthProvider();

        // IMPORTANTE: Usar signInWithRedirect en lugar de signInWithPopup
        await _auth.signInWithRedirect(googleProvider);

        // Después del redirect, obtener el resultado
        final UserCredential? userCredential = await _auth.getRedirectResult();

        if (userCredential != null && userCredential.user != null) {
          print('✅ Login exitoso: ${userCredential.user!.email}');
          await _createUserProfile(userCredential.user!);
          return userCredential.user;
        }

        // Si no hay resultado aún, esperar al siguiente ciclo
        return null;
      } else {
        // EN MÓVIL: Usar el método normal
        print('📱 Iniciando Google Sign-In en MÓVIL');

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          print('⚠️ Usuario canceló el login');
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        if (userCredential.user != null) {
          print('✅ Login exitoso: ${userCredential.user!.email}');
          await _createUserProfile(userCredential.user!);
        }

        return userCredential.user;
      }
    } catch (e) {
      print('❌ Error en inicio de sesion con Google: $e');
      return null;
    }
  }

  Future<void> _createUserProfile(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        print('📝 Creando perfil de usuario para: ${user.email}');

        await userRef.set({
          'displayName': user.displayName ?? 'Usuario',
          'email': user.email ?? '',
          'photoURL': user.photoURL,
          'bio': '',
          'followers': [],
          'following': [],
          'postsCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ Perfil creado exitosamente');
      } else {
        print('✅ Perfil ya existe');
      }
    } catch (e) {
      print('⚠️ Error al crear perfil (no crítico): $e');
      // No lanzar error - el usuario puede seguir usando la app
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
      print('✅ Sesión cerrada correctamente');
    } catch (e) {
      print('❌ Error al cerrar sesion: $e');
    }
  }

  Map<String, dynamic>? getUserInfo() {
    final user = _auth.currentUser;
    if (user != null) {
      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
      };
    }
    return null;
  }
}
