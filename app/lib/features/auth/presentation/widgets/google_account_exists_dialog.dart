import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';

Future<void> showGoogleAccountExistsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => const GoogleAccountExistsDialog(),
  );
}

class GoogleAccountExistsDialog extends StatelessWidget {
  const GoogleAccountExistsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cuenta existente'),
      content: const Text(
        'Ya tienes una cuenta con Google. Inicia '
        'sesión con Google directamente.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<AuthBloc>().add(const GoogleSignInSubmitted());
          },
          child: const Text('Continuar con Google'),
        ),
      ],
    );
  }
}
