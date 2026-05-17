import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:okey_master/services/auth_service.dart';

// --- 1. FIREBASE CORE MOCK ---
class MockFirebasePlatform extends FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return FirebaseAppPlatform(
      name,
      const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project-id',
      ),
    );
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({String? name, FirebaseOptions? options}) async {
    return app(name ?? defaultFirebaseAppName);
  }
}

// --- 2. FIREBASE AUTH MOCK ---
class MockUserPlatform extends Fake with MockPlatformInterfaceMixin implements UserPlatform {
  @override
  String get uid => 'mock_user_id';

  @override
  Future<UserCredentialPlatform> linkWithCredential(AuthCredential credential) async {
    return MockUserCredentialPlatform();
  }

  @override
  Future<void> updatePassword(String newPassword) async {}
}

class MockUserCredentialPlatform extends Fake with MockPlatformInterfaceMixin implements UserCredentialPlatform {
  @override
  UserPlatform? get user => MockUserPlatform();

  @override
  get additionalUserInfo => null;
}

class MockFirebaseAuthPlatform extends Fake with MockPlatformInterfaceMixin implements FirebaseAuthPlatform {
  bool shouldFail = false;

  @override
  FirebaseAuthPlatform delegateFor({FirebaseApp? app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({dynamic currentUser, String? languageCode}) => this;

  @override
  UserPlatform? get currentUser => shouldFail ? null : MockUserPlatform();

  @override
  Future<UserCredentialPlatform> signInAnonymously() async {
    if (shouldFail) throw Exception('Auth Error');
    return MockUserCredentialPlatform();
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(String email, String password) async {
    if (shouldFail) throw Exception('Auth Error');
    return MockUserCredentialPlatform();
  }

  @override
  Future<UserCredentialPlatform> createUserWithEmailAndPassword(String email, String password) async {
    if (shouldFail) throw Exception('Auth Error');
    return MockUserCredentialPlatform();
  }

  @override
  Future<UserCredentialPlatform> signInWithCredential(AuthCredential credential) async {
    if (shouldFail) throw Exception('Auth Error');
    return MockUserCredentialPlatform();
  }

  @override
  Future<void> signOut() async {}
}

// --- 3. GOOGLE SIGN IN MOCK ---
class MockGoogleSignInPlatform extends Fake with MockPlatformInterfaceMixin implements GoogleSignInPlatform {
  bool shouldFail = false;

  @override
  bool get isMock => true;

  @override
  Stream<GoogleSignInUserData?> get userDataEvents => const Stream.empty();

  @override
  Future<void> init({List<String> scopes = const <String>[], SignInOption signInOption = SignInOption.standard, String? hostedDomain, String? clientId}) async {}

  @override
  Future<void> initWithParams(SignInInitParameters params) async {}

  @override
  Future<GoogleSignInUserData?> signIn() async {
    if (shouldFail) return null; 
    return GoogleSignInUserData(
      email: 'test@google.com',
      id: 'google_id',
      displayName: 'Test User',
      idToken: 'mock_id_token',
    );
  }

  @override
  Future<GoogleSignInTokenData> getTokens({required String email, bool? shouldRecoverAuth}) async {
    return GoogleSignInTokenData(idToken: 'mock_id_token', accessToken: 'mock_access_token');
  }

  @override
  Future<void> signOut() async {}
}

// --- TEST KURULUMU ---
void setupAuthMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  FirebasePlatform.instance = MockFirebasePlatform();
  
  // Native kanalları susturuyoruz
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_auth'),
    (MethodCall methodCall) async => null,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/google_sign_in'),
    (MethodCall methodCall) async => null,
  );
}

void main() {
  setupAuthMocks();
  
  late MockFirebaseAuthPlatform mockAuth;
  late MockGoogleSignInPlatform mockGoogle;

  setUpAll(() async {
    await Firebase.initializeApp();
    
    // Auth ve Google platformlarımızı sahteleriyle değiştiriyoruz
    mockAuth = MockFirebaseAuthPlatform();
    mockGoogle = MockGoogleSignInPlatform();
    
    FirebaseAuthPlatform.instance = mockAuth;
    GoogleSignInPlatform.instance = mockGoogle;
  });

  setUp(() async {
    // Her testten önce hataları (fail state) sıfırla
    mockAuth.shouldFail = false;
    mockGoogle.shouldFail = false;

    await AuthService.signOut();
  });

  group('AuthService Testleri', () {
    
    test('currentUser dolu dönmeli', () {
      final user = AuthService.currentUser;
      expect(user, isNotNull);
      expect(user?.uid, 'mock_user_id');
    });

    test('signInAsGuest başarılı olduğunda Exception fırlatmamalı', () async {
      expect(() async => await AuthService.signInAsGuest(), returnsNormally);
    });

    test('signInAsGuest başarısız olduğunda özel hata mesajı fırlatmalı', () async {
      mockAuth.shouldFail = true;
      expect(
        () async => await AuthService.signInAsGuest(),
        throwsA(predicate((e) => e.toString().contains("Misafir girişi başarısız"))),
      );
    });

    test('signInWithEmail başarılı olduğunda çalışmalı', () async {
      expect(() async => await AuthService.signInWithEmail('test@test.com', '123456'), returnsNormally);
    });

    test('registerWithEmail başarısız olduğunda özel hata mesajı fırlatmalı', () async {
      mockAuth.shouldFail = true;
      expect(
        () async => await AuthService.registerWithEmail('test@test.com', '123456'),
        throwsA(predicate((e) => e.toString().contains("Kayıt başarısız"))),
      );
    });

    test('signInWithGoogle başarılı olduğunda çalışmalı', () async {
      expect(() async => await AuthService.signInWithGoogle(), returnsNormally);
    });

    test('signInWithGoogle iptal edildiğinde (null döndüğünde) hata fırlatmalı', () async {
      mockGoogle.shouldFail = true; // Google null dönecek
      expect(
        () async => await AuthService.signInWithGoogle(),
        throwsA(predicate((e) => e.toString().contains("Giriş iptal edildi"))),
      );
    });

    test('linkWithGoogle başarılı olduğunda çalışmalı', () async {
      expect(() async => await AuthService.linkWithGoogle(), returnsNormally);
    });

    test('linkWithEmail başarılı olduğunda çalışmalı', () async {
      expect(() async => await AuthService.linkWithEmail('test@test.com', '123456'), returnsNormally);
    });

    test('linkWithEmail kullanıcı yokken çağrılırsa hata fırlatmalı', () async {
      mockAuth.shouldFail = true; // currentUser null dönecek
      expect(
        () async => await AuthService.linkWithEmail('test@test.com', '123456'),
        throwsA(predicate((e) => e.toString().contains("Oturum açık bir kullanıcı bulunamadı"))),
      );
    });

    test('changePassword başarılı olduğunda çalışmalı', () async {
      expect(() async => await AuthService.changePassword('yeni_sifre'), returnsNormally);
    });

    test('signOut başarılı şekilde çalışmalı', () async {
      expect(() async => await AuthService.signOut(), returnsNormally);
    });
  });
}