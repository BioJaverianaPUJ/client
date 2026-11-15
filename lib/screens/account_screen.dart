import 'package:flutter/material.dart';
import '../state/app_scope.dart';
import '../widgets/community_widgets.dart';

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
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = AppScope.read(context);
    if (widget.delete) {
      if (!await confirmAction(
        context,
        'Eliminar definitivamente mi cuenta',
        'Esta acción no se puede deshacer.',
      )) {
        return;
      }
    } else if (!_form.currentState!.validate()) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.delete) {
        await session.account.deleteAccount();
        await session.logout();
      } else {
        await session.account.changePassword(_current.text, _next.text);
        if (mounted) {
          showMessage(context, 'Contraseña actualizada.');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = AppScope.watch(context).account;
    final available = widget.delete
        ? account.deletionAvailable
        : account.passwordChangeAvailable;
    return CommunityScaffold(
      title: widget.delete ? 'Eliminar mi cuenta' : 'Cambiar contraseña',
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.delete)
              const Text(
                'Se eliminarán tu cuenta, observaciones, fotografías, publicaciones, comentarios y las denuncias recibidas sobre tu contenido. Los me gusta y las denuncias que realizaste se conservarán. No podrás volver a iniciar sesión con esta cuenta.',
              )
            else ...[
              _field(
                _current,
                'Contraseña actual',
                (v) => v == null || v.isEmpty
                    ? 'Ingresa tu contraseña actual.'
                    : null,
              ),
              _field(
                _next,
                'Nueva contraseña',
                (v) => v == null || v.length < 8 || v.length > 72
                    ? 'Debe tener entre 8 y 72 caracteres.'
                    : null,
              ),
              _field(
                _confirm,
                'Repite la nueva contraseña',
                (v) => v != _next.text ? 'Las contraseñas no coinciden.' : null,
              ),
            ],
            if (!available)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Esta función aún no está disponible. No se realizarán cambios en tu cuenta.',
                ),
              ),
            if (_error != null) Text(_error!),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: available && !_busy ? _save : null,
              child: Text(
                widget.delete ? 'Eliminar mi cuenta' : 'Guardar contraseña',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?) validate,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_busy,
      obscureText: true,
      maxLength: 72,
      validator: validate,
      decoration: InputDecoration(labelText: label),
    ),
  );
}
