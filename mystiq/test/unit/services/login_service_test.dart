import 'package:flutter/material.dart' hide Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mystiq_fortune_app/homepage_routing/login_page.dart';
import 'package:mystiq_fortune_app/homepage_routing/register_page.dart';
import 'package:mystiq_fortune_app/pages/MainPage/main_page_fortune_teller.dart';
import 'package:mystiq_fortune_app/pages/MainPage/main_page_normal_user.dart';
import 'package:mystiq_fortune_app/onboarding_screen/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mystiq_fortune_app/backend/session_service.dart';
import 'dart:ui' as dart_ui;

@GenerateMocks([
  Db, 
  DbCollection, 
  GoogleSignIn, 
  GoogleSignInAccount,
  SharedPreferences,
  SessionService
])
import 'login_service_test.mocks.dart';

class FakeWriteResult extends Fake implements WriteResult {}

void main() {
  late MockDb mockDb;
  late MockDbCollection mockCollection;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockGoogleSignInAccount mockGoogleAccount;
  late MockSharedPreferences mockPrefs;
  late MockSessionService mockSessionService;
  late WriteResult fakeWriteResult;
  late LoginPage loginPage;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockDb = MockDb();
    mockCollection = MockDbCollection();
    mockGoogleSignIn = MockGoogleSignIn();
    mockGoogleAccount = MockGoogleSignInAccount();
    mockPrefs = MockSharedPreferences();
    mockSessionService = MockSessionService();
    fakeWriteResult = FakeWriteResult();
    loginPage = LoginPage(
      role: '',
      db: mockDb,
      usersCollection: mockCollection,
      googleSignIn: mockGoogleSignIn,
      sessionService: mockSessionService,
      assetPath: 'assets/dummy.svg',
    );
    // Tüm db ve collection fonksiyonlarını mock'la
    when(mockDb.open()).thenAnswer((_) async => null);
    when(mockDb.close()).thenAnswer((_) async => null);
    when(mockCollection.insertOne(any)).thenAnswer((_) async => fakeWriteResult);
    when(mockCollection.updateOne(any, any)).thenAnswer((_) async => fakeWriteResult);
    when(mockCollection.deleteOne(any)).thenAnswer((_) async => fakeWriteResult);
    // Ekran boyutunu ayarla
    TestWidgetsFlutterBinding.ensureInitialized().window.physicalSizeTestValue = const dart_ui.Size(800, 1200);
    TestWidgetsFlutterBinding.ensureInitialized().window.devicePixelRatioTestValue = 1.0;
  });

  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().window.clearPhysicalSizeTestValue();
    TestWidgetsFlutterBinding.ensureInitialized().window.clearDevicePixelRatioTestValue();
  });

  group('LoginPage Tests', () {
    testWidgets('Boş alanlarla giriş yapılamaz', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: loginPage,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Please enter all fields!'), findsOneWidget);
    });

    testWidgets('Yanlış e-posta/şifre ile giriş yapılamaz', (tester) async {
      when(mockCollection.findOne({
        'email': 'wrong@example.com',
        'password': 'wrongpass'
      })).thenAnswer((_) async => null);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: loginPage,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'wrong@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('E-posta veya şifre yanlış!'), findsOneWidget);
    });

    testWidgets('Fortune Teller rolü ile başarılı giriş', (tester) async {
      when(mockCollection.findOne({
        'email': 'fortune@example.com',
        'password': 'password123'
      })).thenAnswer((_) async => {
        'email': 'fortune@example.com',
        'role': 'Fortune Teller',
        'name': 'Test Fortune Teller'
      });
      when(mockSessionService.saveSession('fortune@example.com', 'Fortune Teller'))
          .thenAnswer((_) async => {});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: loginPage,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'fortune@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Giriş başarılı!'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(MainPageFortuneTeller), findsOneWidget);
    });

    testWidgets('Regular User rolü ile başarılı giriş - Onboarding gerekli', (tester) async {
      when(mockCollection.findOne({
        'email': 'user@example.com',
        'password': 'password123'
      })).thenAnswer((_) async => {
        'email': 'user@example.com',
        'role': 'Regular User',
        'name': 'Test User'
      });
      when(mockSessionService.saveSession('user@example.com', 'Regular User'))
          .thenAnswer((_) async => {});
      when(mockCollection.findOne({
        'email': 'user@example.com',
        'name': {'\$exists': true},
        'birth-date': {'\$exists': true},
        'birth-time': {'\$exists': true},
        'gender': {'\$exists': true},
        'marital-status': {'\$exists': true},
      })).thenAnswer((_) async => null);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: loginPage,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Giriş başarılı!'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('Regular User rolü ile başarılı giriş - Ana sayfaya yönlendirme', (tester) async {
      when(mockCollection.findOne({
        'email': 'user@example.com',
        'password': 'password123'
      })).thenAnswer((_) async => {
        'email': 'user@example.com',
        'role': 'Regular User',
        'name': 'Test User'
      });
      when(mockSessionService.saveSession('user@example.com', 'Regular User'))
          .thenAnswer((_) async => {});
      when(mockCollection.findOne({
        'email': 'user@example.com',
        'name': {'\$exists': true},
        'birth-date': {'\$exists': true},
        'birth-time': {'\$exists': true},
        'gender': {'\$exists': true},
        'marital-status': {'\$exists': true},
      })).thenAnswer((_) async => {
        'email': 'user@example.com',
        'name': 'Test User',
        'birth-date': '2000-01-01',
        'birth-time': '12:00',
        'gender': 'Male',
        'marital-status': 'Single'
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: loginPage,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Giriş başarılı!'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(MainPageNormalUser), findsOneWidget);
    });

    testWidgets('Google ile giriş - Yeni kullanıcı', (tester) async {
      when(mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockGoogleAccount);
      when(mockGoogleAccount.email)
          .thenReturn('new@google.com');
      when(mockCollection.findOne({'email': 'new@google.com'}))
          .thenAnswer((_) async => null);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: loginPage,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log In with Google'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Lütfen önce Google ile kaydolun!'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('Google ile giriş - Var olan kullanıcı', (tester) async {
      when(mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockGoogleAccount);
      when(mockGoogleAccount.email)
          .thenReturn('existing@google.com');
      when(mockGoogleAccount.displayName)
          .thenReturn('Existing User');
      when(mockCollection.findOne({'email': 'existing@google.com'}))
          .thenAnswer((_) async => {
                'email': 'existing@google.com',
                'role': 'Regular User',
                'name': 'Existing User'
              });
      when(mockSessionService.saveSession('existing@google.com', 'Regular User'))
          .thenAnswer((_) async => {});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: loginPage,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log In with Google'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(MainPageNormalUser), findsOneWidget);
    });

    testWidgets('Şifremi unuttum - Geçersiz e-posta', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: loginPage,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.enterText(find.byType(TextField).first, 'invalid-email');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('Şifremi unuttum - Geçerli e-posta', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: loginPage,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.enterText(find.byType(TextField).first, 'valid@example.com');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Reset code has been sent to your email.'), findsOneWidget);
    });
  });
} 