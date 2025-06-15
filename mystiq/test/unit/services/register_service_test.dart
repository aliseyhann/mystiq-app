import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:mystiq_fortune_app/homepage_routing/register_page.dart';
import 'package:mystiq_fortune_app/homepage_routing/login_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

@GenerateMocks([Db, DbCollection, GoogleSignIn, GoogleSignInAccount, WriteResult])
import 'register_service_test.mocks.dart';

void main() {
  late MockDb mockDb;
  late MockDbCollection mockCollection;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockGoogleSignInAccount mockGoogleAccount;
  late MockWriteResult mockWriteResult;
  late RegisterPage registerPage;

  setUp(() {
    mockDb = MockDb();
    mockCollection = MockDbCollection();
    mockGoogleSignIn = MockGoogleSignIn();
    mockGoogleAccount = MockGoogleSignInAccount();
    mockWriteResult = MockWriteResult();
    registerPage = RegisterPage(role: '', assetPath: 'assets/dummy.svg');
  });

  group('RegisterPage Tests', () {
    testWidgets('Boş alanlarla kayıt olunamaz', (tester) async {
      await tester.pumpWidget(MaterialApp(home: registerPage));
      await tester.pumpAndSettle();

      // Kayıt butonuna tıkla
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Snackbar mesajını kontrol et
      expect(find.text('Lütfen tüm alanları doldurun!'), findsOneWidget);
    });

    testWidgets('Rol seçilmeden kayıt olunamaz', (tester) async {
      await tester.pumpWidget(MaterialApp(home: registerPage));
      await tester.pumpAndSettle();

      // Email ve şifre gir
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      // Kayıt butonuna tıkla
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Snackbar mesajını kontrol et
      expect(find.text('Lütfen tüm alanları doldurun!'), findsOneWidget);
    });

    testWidgets('Var olan email ile kayıt olunamaz', (tester) async {
      // Mock veritabanı davranışı
      when(mockCollection.findOne({'email': 'existing@example.com'}))
          .thenAnswer((_) async => {'email': 'existing@example.com'});

      await tester.pumpWidget(MaterialApp(home: registerPage));
      await tester.pumpAndSettle();

      // Rol seç
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Regular User').last);
      await tester.pumpAndSettle();

      // Email ve şifre gir
      await tester.enterText(find.byType(TextField).at(0), 'existing@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      // Kayıt butonuna tıkla
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Snackbar mesajını kontrol et
      expect(find.text('Bu e-posta adresi zaten kullanılıyor!'), findsOneWidget);
    });

    testWidgets('Google ile yeni kullanıcı kaydı', (tester) async {
      // Mock Google Sign In
      when(mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockGoogleAccount);
      when(mockGoogleAccount.email)
          .thenReturn('new@google.com');

      // Mock veritabanı davranışı
      when(mockCollection.findOne({'email': 'new@google.com'}))
          .thenAnswer((_) async => null);
      when(mockCollection.insertOne(any))
          .thenAnswer((_) async => mockWriteResult);

      await tester.pumpWidget(MaterialApp(home: registerPage));
      await tester.pumpAndSettle();

      // Rol seç
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Regular User').last);
      await tester.pumpAndSettle();

      // Google ile kayıt butonuna tıkla
      await tester.tap(find.text('Sign Up with Google'));
      await tester.pumpAndSettle();

      // Login sayfasına yönlendirildiğini kontrol et
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Google ile var olan kullanıcı girişi', (tester) async {
      // Mock Google Sign In
      when(mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockGoogleAccount);
      when(mockGoogleAccount.email)
          .thenReturn('existing@google.com');

      // Mock veritabanı davranışı
      when(mockCollection.findOne({'email': 'existing@google.com'}))
          .thenAnswer((_) async => {
                'email': 'existing@google.com',
                'role': 'Regular User',
                'createdAt': DateTime.now()
              });

      await tester.pumpWidget(MaterialApp(home: registerPage));
      await tester.pumpAndSettle();

      // Rol seç
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Regular User').last);
      await tester.pumpAndSettle();

      // Google ile kayıt butonuna tıkla
      await tester.tap(find.text('Sign Up with Google'));
      await tester.pumpAndSettle();

      // Login sayfasına yönlendirildiğini kontrol et
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Veritabanı bağlantı hatası', (tester) async {
      // Mock veritabanı hatası
      when(mockDb.open()).thenThrow(Exception('Connection error'));

      await tester.pumpWidget(MaterialApp(home: registerPage));
      await tester.pumpAndSettle();

      // Rol seç
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Regular User').last);
      await tester.pumpAndSettle();

      // Email ve şifre gir
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      // Kayıt butonuna tıkla
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Hata mesajını kontrol et
      expect(find.text('Veritabanı bağlantı hatası!'), findsOneWidget);
    });
  });
} 