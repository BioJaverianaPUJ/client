import 'package:flutter/material.dart';
import '../state/app_scope.dart';
import '../theme/bio_theme.dart';
import '../widgets/community_widgets.dart';

/// Cambio de contraseña (RF-40) y eliminación de la cuenta (RF-41).
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, this.delete = false});
  final bool delete;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController(),
      _next = TextEditingController(),
      _confirm = TextEditingController();
  bool _busy = false, _hide = true;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final session = AppScope.read(context);
    if (widget.delete &&
        !await confirmAction(
          context,
          'Eliminar definitivamente mi cuenta',
          'Se borrarán tu cuenta y todo tu contenido. Esta acción no se puede deshacer.',
        )) {
      return;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.delete) {
        await session.account.deleteAccount(
          email: session.user?.email ?? '',
          password: _current.text,
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Tu cuenta y tus datos se eliminaron.')),
        );
        await session.logout();
      } else {
        await session.account.changePassword(_current.text, _next.text);
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Tu contraseña se actualizó.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _error = messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?) validate, {
    bool obscure = true,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      enabled: !_busy,
      obscureText: obscure && _hide,
      maxLength: 72,
      validator: validate,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        suffixIcon: obscure
            ? IconButton(
                tooltip: _hide ? 'Mostrar contraseñas' : 'Ocultar contraseñas',
                onPressed: () => setState(() => _hide = !_hide),
                icon: Icon(
                  _hide
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final account = AppScope.watch(context).account;
    final available = widget.delete
        ? account.deletionAvailable
        : account.passwordChangeAvailable;
    const items = [
      'Tus observaciones y fotografías',
      'Tus publicaciones, imágenes y comentarios',
      'Tu experiencia, misiones y logros',
      'Las denuncias recibidas sobre tu contenido',
    ];
    return CommunityScaffold(
      title: widget.delete ? 'Eliminar mi cuenta' : 'Cambiar contraseña',
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            BioGlassCard(
              frosted: true,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.delete
                            ? Icons.warning_amber_rounded
                            : Icons.lock_reset_rounded,
                        color: widget.delete
                            ? BioTheme.danger
                            : BioTheme.lime,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.delete
                              ? 'Esta acción es permanente'
                              : 'Protege tu cuenta',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (widget.delete) ...[
                    const Text(
                      'Al eliminar tu cuenta se borrará:',
                      style: TextStyle(color: BioTheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '•  ',
                              style: TextStyle(color: BioTheme.danger),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  color: BioTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    const Text(
                      'No podrás volver a iniciar sesión con esta cuenta. Para confirmar, escribe tu contraseña actual.',
                      style: TextStyle(color: BioTheme.textSecondary),
                    ),
                  ] else
                    const Text(
                      'Usa entre 8 y 72 caracteres. La nueva contraseña debe ser distinta de la actual.',
                      style: TextStyle(color: BioTheme.textSecondary),
                    ),
                ],
              ),
            ),
            _field(
              _current,
              'Contraseña actual',
              (v) => v == null || v.isEmpty
                  ? 'Ingresa tu contraseña actual.'
                  : null,
            ),
            if (!widget.delete) ...[
              _field(
                _next,
                'Nueva contraseña',
                (v) => v == null || v.length < 8 || v.length > 72
                    ? 'Debe tener entre 8 y 72 caracteres.'
                    : v == _current.text
                    ? 'Debe ser diferente de la actual.'
                    : null,
              ),
              _field(
                _confirm,
                'Repite la nueva contraseña',
                (v) => v != _next.text ? 'Las contraseñas no coinciden.' : null,
              ),
            ] else
              _field(
                _confirm,
                'Escribe ELIMINAR para confirmar',
                (v) => v?.trim().toUpperCase() != 'ELIMINAR'
                    ? 'Escribe ELIMINAR para confirmar.'
                    : null,
                obscure: false,
                hint: 'ELIMINAR',
              ),
            if (!available)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Esta función aún no está disponible. No se realizarán cambios en tu cuenta.',
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: BioTheme.danger),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: widget.delete
                  ? FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8C3B2E),
                      foregroundColor: Colors.white,
                    )
                  : null,
              onPressed: available && !_busy ? _save : null,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      widget.delete
                          ? Icons.delete_forever_outlined
                          : Icons.check_rounded,
                    ),
              label: Text(
                _busy
                    ? 'Espera un momento…'
                    : widget.delete
                    ? 'Eliminar mi cuenta'
                    : 'Guardar contraseña',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
