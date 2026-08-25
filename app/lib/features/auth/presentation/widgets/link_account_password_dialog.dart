import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';

Future<void> showLinkAccountPasswordDialog(
  BuildContext context, {
  required String email,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => LinkAccountPasswordDialog(email: email),
  );
}

class LinkAccountPasswordDialog extends StatefulWidget {
  const LinkAccountPasswordDialog({super.key, required this.email});

  final String email;

  @override
  State<LinkAccountPasswordDialog> createState() =>
      _LinkAccountPasswordDialogState();
}

class _LinkAccountPasswordDialogState extends State<LinkAccountPasswordDialog> {
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      return;
    }
    context.read<AuthBloc>().add(
      LinkAccountWithPasswordRequested(
        email: widget.email,
        password: password,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vincula tus cuentas'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ya tienes una cuenta con ${widget.email}. '
            'Introduce tu contraseña para vincular '
            'el acceso con Google.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Contraseña'),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Vincular cuentas'),
        ),
      ],
    );
  }
}
