import 'dart:convert';

import 'package:biojaveriana/main.dart';
import 'package:biojaveriana/models/auth_session.dart';
import 'package:biojaveriana/services/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late FakeBackend backend;
  late MemorySessionStorage storage;

  setUp(() {
    backend = FakeBackend();
    storage = MemorySessionStorage();
    backend.on('GET', '/users/me', (_) => json(profileJson()));
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = backend.controller(storage);
    addTearDown(session.dispose);
    await session.restore();
    await tester.pumpWidget(BioJaverianaApp(session: session));
    await tester.pumpAndSettle();
  }

  Finder field(String hint) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == hint,
  );

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('El login se muestra sin acceso de administrador', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.textContaining('administrador'), findsNothing);
  });

  testWidgets('Valida los campos antes de llamar al servidor', (tester) async {
    await pumpApp(tester);

    await tapVisible(tester, find.text('Iniciar sesión'));

    expect(find.text('Ingresa tu correo y tu contraseña.'), findsOneWidget);
    expect(backend.requests, isEmpty);
  });

  testWidgets('Muestra el error de credenciales del servidor', (tester) async {
    backend.on(
      'POST',
      '/auth/login',
      (_) => json({
        'status': 401,
        'code': 'INVALID_CREDENTIALS',
        'message': 'Incorrect email or password',
      }, 401),
    );
    await pumpApp(tester);

    await tester.enterText(field('usuario@javeriana.edu.co'), 'a@b.co');
    await tester.enterText(field('Ingresa tu contraseña'), 'equivocada');
    await tapVisible(tester, find.text('Iniciar sesión'));

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(storage.session, isNull);
  });

  testWidgets('Inicia sesión, muestra el perfil real y cierra sesión', (
    tester,
  ) async {
    backend.on('POST', '/auth/login', (_) => json(sessionJson()));
    await pumpApp(tester);

    await tester.enterText(
      field('usuario@javeriana.edu.co'),
      ' brayan@example.com ',
    );
    await tester.enterText(field('Ingresa tu contraseña'), 'clave-segura');
    await tapVisible(tester, find.text('Iniciar sesión'));

    final login = backend.requests.first;
    expect(jsonDecode(login.body), {
      'email': 'brayan@example.com',
      'password': 'clave-segura',
    });
    expect(find.text('¿Qué descubriste hoy en el campus?'), findsOneWidget);
    expect(storage.session?.token, 'token-de-prueba');

    await tapVisible(tester, find.text('Perfil'));
    final me = backend.requests.firstWhere((r) => r.url.path.endsWith('/me'));
    expect(me.headers['Authorization'], 'Bearer token-de-prueba');
    expect(find.text('Brayan Fajardo'), findsOneWidget);
    expect(find.text('@brayanfajardo'), findsOneWidget);

    // Las opciones de cuenta viven en el menú de configuración del perfil.
    await tapVisible(tester, find.byTooltip('Configuración'));
    await tapVisible(tester, find.text('Cerrar sesión'));

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(storage.session, isNull);
  });

  testWidgets('Registra al usuario con los campos que pide el servidor', (
    tester,
  ) async {
    backend.on('POST', '/auth/register', (_) => json(sessionJson()));
    await pumpApp(tester);

    await tapVisible(
      tester,
      find.textContaining('Crear cuenta', findRichText: true),
    );
    await tester.enterText(field('Ingresa tu nombre'), 'Brayan');
    await tester.enterText(field('Ingresa tu apellido'), 'Fajardo');
    await tester.enterText(field('Entre 3 y 25 caracteres'), 'brayanfajardo');
    await tester.enterText(
      field('usuario@javeriana.edu.co'),
      'brayan@example.com',
    );
    await tapVisible(tester, find.text('Masculino'));
    await tester.enterText(field('Mínimo 8 caracteres'), 'clave-segura');
    await tester.enterText(field('Repite tu contraseña'), 'clave-segura');

    // RF-03: sin aceptar la política no se envía el registro.
    await tapVisible(tester, find.text('Crear cuenta').last);
    expect(backend.requests.where((r) => r.method == 'POST'), isEmpty);
    expect(
      find.text(
        'Para crear tu cuenta debes aceptar la política de tratamiento de datos.',
      ),
      findsOneWidget,
    );

    await tapVisible(tester, find.byType(Checkbox));
    await tapVisible(tester, find.text('Crear cuenta').last);

    final register = backend.requests.firstWhere(
      (request) => request.method == 'POST',
    );
    expect(register.url.path, '/api/v1/auth/register');
    final body = jsonDecode(register.body) as Map<String, dynamic>;
    final acceptedAt = body.remove('dataPolicyAcceptedAt');
    expect(DateTime.tryParse(acceptedAt as String), isNotNull);
    expect(body.remove('dataPolicyVersion'), isNotEmpty);
    expect(body, {
      'firstName': 'Brayan',
      'lastName': 'Fajardo',
      'username': 'brayanfajardo',
      'email': 'brayan@example.com',
      'gender': 'MALE',
      'password': 'clave-segura',
    });
    expect(find.text('¿Qué descubriste hoy en el campus?'), findsOneWidget);
  });

  testWidgets('Una sesión guardada vigente entra directo al inicio', (
    tester,
  ) async {
    storage.session = AuthSession.fromJson(sessionJson());
    await pumpApp(tester);

    expect(find.text('¿Qué descubriste hoy en el campus?'), findsOneWidget);
  });

  testWidgets('Una sesión guardada vencida vuelve al login con aviso', (
    tester,
  ) async {
    storage.session = AuthSession.fromJson(
      sessionJson(validFor: const Duration(minutes: -5)),
    );
    await pumpApp(tester);

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(
      find.text('Tu sesión expiró. Inicia sesión de nuevo.'),
      findsOneWidget,
    );
    expect(storage.session, isNull);
  });

  test('Traduce los códigos de error del servidor', () {
    final taken = ApiException.fromResponse(
      409,
      '{"status":409,"code":"USERNAME_ALREADY_EXISTS"}',
    );
    final invalid = ApiException.fromResponse(400, 'no es json');

    expect(taken.kind, ApiErrorKind.usernameTaken);
    expect(taken.message, 'Ese nombre de usuario ya está en uso.');
    expect(invalid.kind, ApiErrorKind.validation);
  });
  testWidgets('Registro y login admiten texto al 200% sin desbordes', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester);
    expect(tester.takeException(), isNull);
    await tapVisible(
      tester,
      find.textContaining('Crear cuenta', findRichText: true),
    );
    await tester.scrollUntilVisible(
      find.text('Política de tratamiento de datos'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.text('Política de tratamiento de datos'));
    expect(find.textContaining('aún no está disponible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
