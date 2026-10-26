import 'package:flutter/material.dart';

import '../../theme/bio_icons.dart';
import '../../theme/bio_theme.dart';
import '../../widgets/auth/auth_layout.dart';
import '../../widgets/auth/glass_text_field.dart';
import '../../widgets/bio_illustration.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/liquid_glass.dart';
import '../../widgets/glass/soft_frost_glass.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    if (_email.text.trim().isEmpty) {
      return;
    }

    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      minContentHeight: 820,
      decorations: const [
        BioIllustration(
          asset: 'assets/illustrations/cat_facing_back.png',
          color: BioTheme.botanical,
          opacity: 0.22,
          right: -105,
          bottom: 35,
          width: 410,
          height: 410,
        ),
      ],
      children: [
        const SizedBox(height: 30),
        SoftFrostGlass(
          borderRadius: 40,
          padding: const EdgeInsets.fromLTRB(23, 28, 23, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: LiquidGlass(
                  borderRadius: 15,
                  blur: false,
                  width: 39,
                  height: 39,
                  child: Center(
                    child: Icon(
                      BioIcons.shieldKeyOutline,
                      size: 17,
                      color: BioTheme.lime,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const AuthHeading(
                eyebrow: 'RECUPERA TU ACCESO',
                title: 'Recuperar\ncontraseña',
                subtitle: 'Ingresa tu correo institucional y te enviaremos '
                    'las instrucciones para recuperar el acceso a tu cuenta.',
                titleSize: 37,
                titleHeight: 39,
                titleLetterSpacing: -1.45,
                subtitleSize: 13,
                subtitleHeight: 19,
                subtitleTop: 12,
                subtitleMaxWidth: double.infinity,
                dividerSpacing: 22,
              ),
              GlassTextField(
                label: 'Correo institucional',
                icon: BioIcons.emailOutline,
                controller: _email,
                hint: 'usuario@javeriana.edu.co',
                keyboardType: TextInputType.emailAddress,
                glyphSize: 19,
                fontSize: 13,
                bottomSpacing: 20,
                onChanged: (_) {
                  if (_sent) {
                    setState(() => _sent = false);
                  }
                },
              ),
              if (_sent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Transform.translate(
                    offset: const Offset(0, -5),
                    child: LiquidGlass(
                      borderRadius: 18,
                      blur: false,
                      minHeight: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox(
                        height: 46,
                        child: Row(
                          children: [
                            Icon(
                              BioIcons.checkCircleOutline,
                              size: 18,
                              color: BioTheme.lime,
                            ),
                            const SizedBox(width: 9),
                            const Text(
                              'Revisa tu correo institucional.',
                              style: TextStyle(
                                color: Color(0xFFC8D4CD),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              GlassButton(
                title: 'Enviar enlace',
                iconSize: 47,
                height: 61,
                borderRadius: 27,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                onPressed: _send,
              ),
              const SizedBox(height: 17),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    BioIcons.lockOutline,
                    size: 13,
                    color: const Color(0xFF8FA79C),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Tu cuenta y tus datos permanecen protegidos.',
                    style: TextStyle(color: Color(0xFF91A69C), fontSize: 10.5),
                  ),
                ],
              ),
            ],
          ),
        ),
        AuthLink(
          question: 'Volver a',
          action: 'Iniciar sesión',
          top: 23,
          leading: Icon(BioIcons.arrowLeft, size: 15, color: BioTheme.lime),
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
