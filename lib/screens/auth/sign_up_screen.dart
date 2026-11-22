import 'package:flutter/material.dart';

import '../../models/gender.dart';
import '../../models/registration_data.dart';
import '../../navigation/app_routes.dart';
import '../../services/api_exception.dart';
import '../../state/app_scope.dart';
import '../../theme/bio_icons.dart';
import '../../theme/bio_theme.dart';
import '../../widgets/auth/auth_layout.dart';
import '../../widgets/auth/auth_message.dart';
import '../../widgets/auth/glass_text_field.dart';
import '../../widgets/bio_illustration.dart';
import '../../widgets/bio_pressable.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/glass/soft_frost_glass.dart';
import 'data_policy_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  Gender? _gender;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _loading = false;
  bool _acceptedPolicy = false;
  DateTime? _acceptedAt;
  String? _error;

  static const _policyError =
      'Para crear tu cuenta debes aceptar la política de tratamiento de datos.';

  void _setPolicy(bool value) => setState(() {
    _acceptedPolicy = value;
    _acceptedAt = value ? DateTime.now() : null;
    if (value && _error == _policyError) _error = null;
  });

  Future<void> _openPolicy() async {
    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DataPolicyScreen()),
    );
    if (accepted == true && mounted) _setPolicy(true);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String? _validate() {
    final firstName = _firstName.text.trim();
    final lastName = _lastName.text.trim();
    final username = _username.text.trim();
    final password = _password.text;

    if (firstName.isEmpty || lastName.isEmpty) {
      return 'Ingresa tu nombre y tu apellido.';
    }
    if (firstName.length > 50 || lastName.length > 50) {
      return 'El nombre y el apellido pueden tener máximo 50 caracteres.';
    }
    if (username.length < 3 || username.length > 25) {
      return 'El nombre de usuario debe tener entre 3 y 25 caracteres.';
    }
    if (username.contains(RegExp(r'\s'))) {
      return 'El nombre de usuario no puede tener espacios.';
    }
    if (!_emailPattern.hasMatch(_email.text.trim())) {
      return 'Revisa que el correo esté bien escrito.';
    }
    if (_gender == null) {
      return 'Selecciona tu género.';
    }
    if (password.length < 8 || password.length > 72) {
      return 'La contraseña debe tener entre 8 y 72 caracteres.';
    }
    if (password != _confirmPassword.text) {
      return 'Las contraseñas no coinciden.';
    }
    if (!_acceptedPolicy) {
      return _policyError;
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final invalid = _validate();
    setState(() => _error = invalid);
    if (invalid != null) {
      return;
    }

    final data = RegistrationData(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      username: _username.text.trim(),
      email: _email.text.trim(),
      gender: _gender!,
      password: _password.text,
      dataPolicyAcceptedAt: _acceptedAt,
      dataPolicyVersion: dataPolicyVersion,
    );

    setState(() => _loading = true);
    try {
      await AppScope.read(context).register(data);
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

  GlassTextField _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Iterable<String>? autofillHints,
    int? maxLength,
    bool? obscureText,
    VoidCallback? onToggleObscure,
  }) {
    return GlassTextField(
      label: label,
      icon: icon,
      controller: controller,
      hint: hint,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: TextInputAction.next,
      autofillHints: autofillHints,
      maxLength: maxLength,
      obscureText: obscureText ?? false,
      onToggleObscure: onToggleObscure,
      height: 55,
      iconSize: 39,
      fontSize: 13,
      bottomSpacing: 15,
      labelSpacing: 7,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      decorations: const [
        BioIllustration(
          asset: 'assets/illustrations/engraved_birds_blossoms.png',
          color: BioTheme.botanical,
          opacity: 0.11,
          left: -92,
          top: 135,
          width: 500,
          height: 755,
        ),
      ],
      children: [
        const SizedBox(height: 24),
        SoftFrostGlass(
          borderRadius: 40,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 21),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeading(
                  eyebrow: 'ÚNETE A BIOJAVERIANA',
                  title: 'Crear cuenta',
                  subtitle:
                      'Empieza a explorar y descubrir la biodiversidad '
                      'que habita en nuestro campus.',
                  titleSize: 36,
                  titleHeight: 40,
                  titleLetterSpacing: -1.4,
                  subtitleSize: 13,
                  subtitleHeight: 18.5,
                  dividerSpacing: 19,
                ),
                _field(
                  label: 'Nombre',
                  icon: BioIcons.accountOutline,
                  controller: _firstName,
                  hint: 'Ingresa tu nombre',
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.givenName],
                  maxLength: 50,
                ),
                _field(
                  label: 'Apellido',
                  icon: BioIcons.accountOutline,
                  controller: _lastName,
                  hint: 'Ingresa tu apellido',
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.familyName],
                  maxLength: 50,
                ),
                _field(
                  label: 'Nombre de usuario',
                  icon: BioIcons.at,
                  controller: _username,
                  hint: 'Entre 3 y 25 caracteres',
                  autofillHints: const [AutofillHints.newUsername],
                  maxLength: 25,
                ),
                _field(
                  label: 'Correo',
                  icon: BioIcons.emailOutline,
                  controller: _email,
                  hint: 'usuario@javeriana.edu.co',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                _GenderSelector(
                  selected: _gender,
                  onSelected: (gender) => setState(() => _gender = gender),
                ),
                _field(
                  label: 'Contraseña',
                  icon: BioIcons.lockOutline,
                  controller: _password,
                  hint: 'Mínimo 8 caracteres',
                  autofillHints: const [AutofillHints.newPassword],
                  maxLength: 72,
                  obscureText: _hidePassword,
                  onToggleObscure: () =>
                      setState(() => _hidePassword = !_hidePassword),
                ),
                _field(
                  label: 'Confirmar contraseña',
                  icon: BioIcons.shieldLockOutline,
                  controller: _confirmPassword,
                  hint: 'Repite tu contraseña',
                  maxLength: 72,
                  obscureText: _hideConfirmPassword,
                  onToggleObscure: () => setState(
                    () => _hideConfirmPassword = !_hideConfirmPassword,
                  ),
                ),
                _PolicyConsent(
                  accepted: _acceptedPolicy,
                  onChanged: _loading ? null : _setPolicy,
                  onRead: _loading ? null : _openPolicy,
                ),
                if (_error != null) AuthMessage(text: _error!),
                GlassButton(
                  title: 'Crear cuenta',
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
          question: '¿Ya tienes una cuenta?',
          action: 'Iniciar sesión',
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.selected, required this.onSelected});

  final Gender? selected;
  final ValueChanged<Gender> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              'Género',
              style: TextStyle(
                color: Color(0xFFEBF1ED),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final gender in Gender.values)
                _GenderChip(
                  gender: gender,
                  active: gender == selected,
                  onTap: () => onSelected(gender),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.gender,
    required this.active,
    required this.onTap,
  });

  final Gender gender;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      child: BioPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? BioTheme.lime
                : const Color.fromRGBO(255, 255, 255, 0.035),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? BioTheme.lime
                  : const Color.fromRGBO(225, 238, 228, 0.16),
              width: 0.8,
            ),
          ),
          child: Text(
            gender.label,
            style: TextStyle(
              color: active ? BioTheme.backgroundDeep : BioTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Autorización expresa del tratamiento de datos y declaración de mayoría de
/// edad, obligatorias antes de crear la cuenta (RF-03, Ley 1581 de 2012).
class _PolicyConsent extends StatelessWidget {
  const _PolicyConsent({
    required this.accepted,
    required this.onChanged,
    required this.onRead,
  });
  final bool accepted;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onRead;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 4, bottom: 14),
    padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
    decoration: BoxDecoration(
      color: accepted
          ? BioTheme.lime.withValues(alpha: 0.1)
          : const Color.fromRGBO(255, 255, 255, 0.035),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: accepted
            ? BioTheme.lime
            : const Color.fromRGBO(225, 238, 228, 0.16),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: accepted,
          onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
          activeColor: BioTheme.lime,
          checkColor: BioTheme.backgroundDeep,
          side: const BorderSide(color: BioTheme.textSecondary, width: 1.4),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onChanged == null ? null : () => onChanged!(!accepted),
                  child: const Text(
                    'Autorizo el tratamiento de mis datos personales según la política de BioJaveriana y declaro que soy mayor de 18 años.',
                    style: TextStyle(
                      color: Color(0xFFEBF1ED),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onRead,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: BioTheme.lime,
                  ),
                  icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                  label: const Text(
                    'Leer la política de tratamiento de datos',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: BioTheme.lime,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
