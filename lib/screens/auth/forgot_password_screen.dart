import 'package:flutter/material.dart';
import '../../theme/bio_theme.dart';
import '../../widgets/auth/auth_layout.dart';
import '../../widgets/bio_illustration.dart';
import '../../widgets/bio_scene.dart';
import '../../widgets/glass/glass_icon.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) => AuthLayout(
    decorations: const [
      BioIllustration(
        asset: 'assets/illustrations/cat_facing_back.png',
        color: BioTheme.botanical,
        opacity: .24,
        right: -20,
        bottom: 50,
        width: 200,
        height: 420,
      ),
    ],
    children: [
      const SizedBox(height: 24),
      const BioGlassCard(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassIcon(icon: Icons.lock_outline, size: 48, iconSize: 24),
            BioPageHeading(
              eyebrow: 'Recupera tu acceso',
              title: 'Recuperar',
              accent: 'contraseña',
              description: 'Volver a explorar empieza por recuperar tu cuenta.',
            ),
            Divider(),
            Text(
              'Recuperación no disponible',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            Text(
              'Todavía no es posible recuperar tu contraseña desde la aplicación. No se ha enviado ningún correo.',
              style: TextStyle(color: BioTheme.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
      TextButton.icon(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Volver a iniciar sesión'),
      ),
    ],
  );
}
