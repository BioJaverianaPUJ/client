import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';
import '../../services/api_exception.dart';
import '../../state/app_scope.dart';
import '../../theme/bio_icons.dart';
import '../../theme/bio_theme.dart';
import '../../widgets/auth/auth_layout.dart';
import '../../widgets/auth/auth_message.dart';
import '../../widgets/auth/glass_text_field.dart';
import '../../widgets/bio_illustration.dart';
import '../../widgets/glass/glass_button.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/liquid_glass.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final session = AppScope.read(context);
      if (session.suspended) {
        session.clearSuspendedNotice();
        setState(
          () => _notice =
              'Tu cuenta está suspendida. No puedes acceder mientras permanezca bloqueada.',
        );
      } else if (session.sessionExpired) {
        session.clearExpiredNotice();
        setState(() => _notice = 'Tu sesión expiró. Inicia sesión de nuevo.');
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validate(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      return 'Ingresa tu correo y tu contraseña.';
    }
    if (!email.contains('@') || email.startsWith('@') || email.endsWith('@')) {
      return 'Revisa que el correo esté bien escrito.';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final password = _password.text;
    final invalid = _validate(email, password);

    setState(() {
      _error = invalid;
      _notice = null;
    });
    if (invalid != null) {
      return;
    }

    setState(() => _loading = true);
    try {
      await AppScope.read(context).login(email: email, password: password);
      if (!mounted) {
        return;
      }
      AppRoutes.enterApp(context);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final message = _error ?? _notice;

    return AuthLayout(
      decorations: [
        BioIllustration(
          asset: 'assets/illustrations/forest_canopy_1.png',
          color: BioTheme.forest,
          opacity: 0.42,
          left: -125,
          bottom: -8,
          width: width * 1.65,
          height: 430,
          fit: BoxFit.fill,
        ),
        // Rama con el pájaro: queda detrás de la tarjeta (ahora casi
        // transparente) para que se vea a través del vidrio.
        BioIllustration(
          asset: 'assets/illustrations/raven_branch.png',
          color: const Color(0xFF9BB377),
          opacity: 0.62,
          right: -92,
          top: 212,
          width: width * 0.82,
          height: width * 0.82 * 941 / 1672,
          flipHorizontally: true,
        ),
      ],
      children: [
        const SizedBox(height: 27),
        LiquidGlass(
          material: GlassMaterial.airy,
          borderRadius: 40,
          padding: const EdgeInsets.fromLTRB(22, 27, 22, 21),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeading(
                  eyebrow: 'BIODIVERSIDAD JAVERIANA',
                  title: 'Bienvenido',
                  subtitle: 'Explora la vida que habita en nuestro campus.',
                  subtitleMaxWidth: 275,
                ),
                GlassTextField(
                  label: 'Correo',
                  icon: BioIcons.emailOutline,
                  controller: _email,
                  hint: 'usuario@javeriana.edu.co',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                ),
                GlassTextField(
                  label: 'Contraseña',
                  icon: BioIcons.lockOutline,
                  controller: _password,
                  hint: 'Ingresa tu contraseña',
                  obscureText: _hidePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  onToggleObscure: () =>
                      setState(() => _hidePassword = !_hidePassword),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Transform.translate(
                    offset: const Offset(0, -4),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.forgotPassword),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: BioTheme.limeSoft,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                if (message != null)
                  AuthMessage(text: message, isError: _error != null),
                GlassButton(
                  title: 'Iniciar sesión',
                  iconSize: 46,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
        AuthLink(
          question: '¿Aún no tienes una cuenta?',
          action: 'Crear cuenta',
          top: 10,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.signUp),
        ),
      ],
    );
  }
}
