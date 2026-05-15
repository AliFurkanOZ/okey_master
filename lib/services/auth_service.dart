import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Mevcut kullanıcıyı getir
  static User? get currentUser => _auth.currentUser;

  // Anonim (Misafir) Girişi
  static Future<UserCredential> signInAsGuest() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      throw Exception("Misafir girişi başarısız: $e");
    }
  }

  // E-posta ve Şifre ile Giriş
  static Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception("Giriş başarısız: $e");
    }
  }

  // E-posta ve Şifre ile Kayıt
  static Future<UserCredential> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception("Kayıt başarısız: $e");
    }
  }

  // Google ile Giriş
  static Future<UserCredential> signInWithGoogle() async {
    try {
      // Google hesap seçiciyi aç
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception("Giriş iptal edildi.");
      }

      // Kimlik doğrulama detaylarını al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase credential oluştur
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase'e giriş yap
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception("Google ile giriş başarısız: $e");
    }
  }

  // Google ile Hesap Bağlama (Misafir hesabı için)
  static Future<UserCredential> linkWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception("Giriş iptal edildi.");
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final user = currentUser;
      if (user != null) {
        return await user.linkWithCredential(credential);
      } else {
        throw Exception("Oturum açık bir kullanıcı bulunamadı.");
      }
    } catch (e) {
      throw Exception("Google ile bağlama başarısız: $e");
    }
  }

  // E-posta ile Hesap Bağlama (Misafir hesabı için)
  static Future<UserCredential> linkWithEmail(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      final user = currentUser;
      if (user != null) {
        return await user.linkWithCredential(credential);
      } else {
        throw Exception("Oturum açık bir kullanıcı bulunamadı.");
      }
    } catch (e) {
      throw Exception("E-posta ile bağlama başarısız: $e");
    }
  }

  // Şifre Değiştirme
  static Future<void> changePassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception("Oturum açık bir kullanıcı bulunamadı.");
      }
    } catch (e) {
      throw Exception("Şifre değiştirme başarısız: $e");
    }
  }

  // Çıkış Yap
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
