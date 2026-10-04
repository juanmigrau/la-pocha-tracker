import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/services/local_user_service.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';
import 'package:la_pocha/core/widgets/primary_button.dart';
import 'package:la_pocha/features/auth/presentation/widgets/auth_text_field.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final localUserService = getIt<LocalUserService>();
      final name = _nameController.text.trim();
      await localUserService.getOrCreateLocalId();
      await localUserService.setLocalName(name);

      if (!mounted) {
        return;
      }
      context.go('/');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PochaAppBar(
              title: 'La Pocha',
              subtitle: 'Marcador de puntos',
              expanded: true,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 32),
                                Text(
                                  '¿Cómo te llamas?',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: AppTheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Así te reconocerán en las partidas locales.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                AuthTextField(
                                  label: 'Tu nombre',
                                  controller: _nameController,
                                  prefixIcon: Icons.person_outline,
                                  textInputAction: TextInputAction.done,
                                  maxLength: 20,
                                  onFieldSubmitted: (_) {
                                    if (!_isSubmitting) {
                                      _submit();
                                    }
                                  },
                                  validator: (value) {
                                    final trimmed = value?.trim() ?? '';
                                    if (trimmed.isEmpty) {
                                      return 'Introduce tu nombre';
                                    }
                                    if (trimmed.length > 20) {
                                      return 'Máximo 20 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const Spacer(),
                                PrimaryButton(
                                  label: 'Empezar',
                                  isLoading: _isSubmitting,
                                  onPressed: _isSubmitting ? null : _submit,
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
