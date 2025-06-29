// Mocks generated by Mockito 5.4.4 from annotations
// in mystiq_fortune_app/test/backend/email_service_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:mailer/smtp_server.dart' as _i5;
import 'package:mailer/src/entities/address.dart' as _i2;
import 'package:mailer/src/entities/attachment.dart' as _i4;
import 'package:mailer/src/entities/message.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i6;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeAddress_0 extends _i1.SmartFake implements _i2.Address {
  _FakeAddress_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [Message].
///
/// See the documentation for Mockito's code generation for more information.
class MockMessage extends _i1.Mock implements _i3.Message {
  MockMessage() {
    _i1.throwOnMissingStub(this);
  }

  @override
  set envelopeFrom(String? _envelopeFrom) => super.noSuchMethod(
        Invocation.setter(
          #envelopeFrom,
          _envelopeFrom,
        ),
        returnValueForMissingStub: null,
      );

  @override
  set envelopeTos(List<String>? _envelopeTos) => super.noSuchMethod(
        Invocation.setter(
          #envelopeTos,
          _envelopeTos,
        ),
        returnValueForMissingStub: null,
      );

  @override
  set from(dynamic _from) => super.noSuchMethod(
        Invocation.setter(
          #from,
          _from,
        ),
        returnValueForMissingStub: null,
      );

  @override
  List<dynamic> get recipients => (super.noSuchMethod(
        Invocation.getter(#recipients),
        returnValue: <dynamic>[],
      ) as List<dynamic>);

  @override
  set recipients(List<dynamic>? _recipients) => super.noSuchMethod(
        Invocation.setter(
          #recipients,
          _recipients,
        ),
        returnValueForMissingStub: null,
      );

  @override
  List<dynamic> get ccRecipients => (super.noSuchMethod(
        Invocation.getter(#ccRecipients),
        returnValue: <dynamic>[],
      ) as List<dynamic>);

  @override
  set ccRecipients(List<dynamic>? _ccRecipients) => super.noSuchMethod(
        Invocation.setter(
          #ccRecipients,
          _ccRecipients,
        ),
        returnValueForMissingStub: null,
      );

  @override
  List<dynamic> get bccRecipients => (super.noSuchMethod(
        Invocation.getter(#bccRecipients),
        returnValue: <dynamic>[],
      ) as List<dynamic>);

  @override
  set bccRecipients(List<dynamic>? _bccRecipients) => super.noSuchMethod(
        Invocation.setter(
          #bccRecipients,
          _bccRecipients,
        ),
        returnValueForMissingStub: null,
      );

  @override
  Map<String, dynamic> get headers => (super.noSuchMethod(
        Invocation.getter(#headers),
        returnValue: <String, dynamic>{},
      ) as Map<String, dynamic>);

  @override
  set headers(Map<String, dynamic>? _headers) => super.noSuchMethod(
        Invocation.setter(
          #headers,
          _headers,
        ),
        returnValueForMissingStub: null,
      );

  @override
  set subject(String? _subject) => super.noSuchMethod(
        Invocation.setter(
          #subject,
          _subject,
        ),
        returnValueForMissingStub: null,
      );

  @override
  set text(String? _text) => super.noSuchMethod(
        Invocation.setter(
          #text,
          _text,
        ),
        returnValueForMissingStub: null,
      );

  @override
  set html(String? _html) => super.noSuchMethod(
        Invocation.setter(
          #html,
          _html,
        ),
        returnValueForMissingStub: null,
      );

  @override
  List<_i4.Attachment> get attachments => (super.noSuchMethod(
        Invocation.getter(#attachments),
        returnValue: <_i4.Attachment>[],
      ) as List<_i4.Attachment>);

  @override
  set attachments(List<_i4.Attachment>? _attachments) => super.noSuchMethod(
        Invocation.setter(
          #attachments,
          _attachments,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i2.Address get fromAsAddress => (super.noSuchMethod(
        Invocation.getter(#fromAsAddress),
        returnValue: _FakeAddress_0(
          this,
          Invocation.getter(#fromAsAddress),
        ),
      ) as _i2.Address);

  @override
  Iterable<_i2.Address> get recipientsAsAddresses => (super.noSuchMethod(
        Invocation.getter(#recipientsAsAddresses),
        returnValue: <_i2.Address>[],
      ) as Iterable<_i2.Address>);

  @override
  Iterable<_i2.Address> get ccsAsAddresses => (super.noSuchMethod(
        Invocation.getter(#ccsAsAddresses),
        returnValue: <_i2.Address>[],
      ) as Iterable<_i2.Address>);

  @override
  Iterable<_i2.Address> get bccsAsAddresses => (super.noSuchMethod(
        Invocation.getter(#bccsAsAddresses),
        returnValue: <_i2.Address>[],
      ) as Iterable<_i2.Address>);
}

/// A class which mocks [SmtpServer].
///
/// See the documentation for Mockito's code generation for more information.
class MockSmtpServer extends _i1.Mock implements _i5.SmtpServer {
  MockSmtpServer() {
    _i1.throwOnMissingStub(this);
  }

  @override
  String get host => (super.noSuchMethod(
        Invocation.getter(#host),
        returnValue: _i6.dummyValue<String>(
          this,
          Invocation.getter(#host),
        ),
      ) as String);

  @override
  int get port => (super.noSuchMethod(
        Invocation.getter(#port),
        returnValue: 0,
      ) as int);

  @override
  bool get ignoreBadCertificate => (super.noSuchMethod(
        Invocation.getter(#ignoreBadCertificate),
        returnValue: false,
      ) as bool);

  @override
  bool get ssl => (super.noSuchMethod(
        Invocation.getter(#ssl),
        returnValue: false,
      ) as bool);

  @override
  bool get allowInsecure => (super.noSuchMethod(
        Invocation.getter(#allowInsecure),
        returnValue: false,
      ) as bool);
}
