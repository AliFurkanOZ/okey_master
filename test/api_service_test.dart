import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nock/nock.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/services.dart';

import 'package:okey_master/services/api_service.dart';
import 'package:okey_master/utils/constants.dart';

// 1. Firebase Core Mock
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

// 2. Auth ve Token Mock'u
class MockUserPlatform extends Fake with MockPlatformInterfaceMixin implements UserPlatform {
  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    return 'bu_cok_uzun_bir_sahte_token_degeridir_range_error_vermesini_engeller_1234567890';
  }
}

class MockFirebaseAuthPlatform extends Fake with MockPlatformInterfaceMixin implements FirebaseAuthPlatform {
  @override
  FirebaseAuthPlatform delegateFor({FirebaseApp? app}) {
    return this;
  }

  @override
  FirebaseAuthPlatform setInitialValues({
    dynamic currentUser,
    String? languageCode,
  }) {
    return this;
  }

  @override
  UserPlatform? get currentUser => MockUserPlatform();
}

void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = MockFirebasePlatform();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_auth'),
    (MethodCall methodCall) async {
      return null;
    },
  );
}

void main() {
  setupFirebaseMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
    FirebaseAuthPlatform.instance = MockFirebaseAuthPlatform();
    nock.init(); 
  });

  setUp(() {
    nock.cleanAll(); 
  });

  group('ApiService Testleri', () {
    final baseUrl = AppConstants.apiBaseUrl;

    test('registerPlayer başarılı olduğunda (200) kullanıcı adını dönmeli', () async {
      // ÇÖZÜM: 'any' yerine 'anything' kullandık. Artık hata vermeyecek.
      nock(baseUrl).post('/auth/register', anything).reply(200, jsonEncode({'username': 'oyuncu1'}));

      final result = await ApiService.registerPlayer('oyuncu1');

      expect(result['status'], 200);
      expect(result['username'], 'oyuncu1');
    });

    test('registerPlayer başarısız olduğunda (500) username null dönmeli', () async {
      nock(baseUrl).post('/auth/register', anything).reply(500, 'Internal Server Error');

      final result = await ApiService.registerPlayer('oyuncu1');

      expect(result['status'], 500);
      expect(result['username'], null);
    });

    test('updateUsername başarılı olduğunda status 200 dönmeli', () async {
      nock(baseUrl).put('/auth/username', anything).reply(200, 'Success');

      final result = await ApiService.updateUsername('yeni_oyuncu');

      expect(result['status'], 200);
    });

    test('sendResult başarılı olduğunda hata fırlatmamalı', () async {
      nock(baseUrl).post('/games/result', anything).reply(200, 'Success');

      await ApiService.sendResult(
        nickname: 'oyuncu1',
        isWin: true,
        duration: 120,
        type: 'duel',
      );
    });

    test('sendResult sunucu hatası (300+) aldığında ApiException fırlatmalı', () async {
      nock(baseUrl).post('/games/result', anything).reply(400, 'Bad Request');

      await expectLater(
        ApiService.sendResult(
          nickname: 'oyuncu1',
          isWin: true,
          type: 'memory_hard',
        ),
        throwsA(isA<ApiException>()), 
      );
    });

    test('getLeaderboard başarılı olduğunda liste dönmeli', () async {
      final mockData = [
        {'username': 'kral', 'score': 100},
        {'username': 'oyuncu2', 'score': 90}
      ];
      
      nock(baseUrl).get('/leaderboard?type=duel').reply(200, jsonEncode(mockData));

      final result = await ApiService.getLeaderboard('duel');

      expect(result.length, 2);
      expect(result[0]['username'], 'kral');
      expect(result[1]['score'], 90);
    });

    test('getMyStats sunucuya bağlanamadığında veya hata verdiğinde null dönmeli', () async {
      nock(baseUrl).get('/stats/me').reply(404, 'Not Found');

      final result = await ApiService.getMyStats();

      expect(result, isNull); 
    });
  });
}