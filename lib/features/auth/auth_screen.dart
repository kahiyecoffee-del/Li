import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/errors/app_failure.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../services/auth/auth_service.dart';

enum AuthMode { signIn, signUp, link }

/// Email/password + Google sign-in. In [AuthMode.link] it upgrades the
/// current anonymous account instead (same uid, data preserved).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.mode});

  final AuthMode mode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late AuthMode _mode = widget.mode;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  AuthService get _auth => ref.read(servicesProvider).auth;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
      if (!mounted) return;
      if (_mode == AuthMode.link) {
        showSnack(context, context.l10n.accountLinked);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted && !(e is AppFailure && e.kind == FailureKind.cancelled)) showSnack(context, context.l10n.failure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final e = _email.text;
    final p = _password.text;
    await _run(() async {
      switch (_mode) {
        case AuthMode.signIn:
          await _auth.signInWithEmail(e, p);
        case AuthMode.signUp:
          await _auth.createAccountWithEmail(e, p);
        case AuthMode.link:
          await _auth.linkEmail(e, p);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final title = switch (_mode) {
      AuthMode.signIn => l.signIn,
      AuthMode.signUp => l.signUp,
      AuthMode.link => l.linkAccountTitle,
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(Space.xl),
            children: [
              if (_mode == AuthMode.link) ...[
                Text(l.linkAccountBody, style: context.text.bodyLarge),
                const SizedBox(height: Space.xl),
              ],
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        _mode == AuthMode.link ? await _auth.linkGoogle() : await _auth.signInWithGoogle();
                      }),
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: Text(_mode == AuthMode.link ? l.linkGoogle : l.continueWithGoogle),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.lg),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.md),
                      child: Text(l.orDivider),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: l.email),
                validator: (v) =>
                    v != null && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? null : l.errorInvalidInput,
              ),
              const SizedBox(height: Space.md),
              TextFormField(
                controller: _password,
                obscureText: true,
                autofillHints: [_mode == AuthMode.signIn ? AutofillHints.password : AutofillHints.newPassword],
                decoration: InputDecoration(labelText: l.password),
                validator: (v) => (v ?? '').length >= (_mode == AuthMode.signIn ? 1 : 8) ? null : l.errorWeakPassword,
              ),
              const SizedBox(height: Space.xl),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_mode == AuthMode.link ? l.linkEmail : title),
              ),
              if (_mode != AuthMode.link) ...[
                const SizedBox(height: Space.md),
                TextButton(
                  onPressed: () => setState(() => _mode = _mode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn),
                  child: Text(_mode == AuthMode.signIn ? l.signUp : l.signIn),
                ),
                if (_mode == AuthMode.signIn)
                  TextButton(
                    onPressed: () => _run(() async {
                      await _auth.sendPasswordReset(_email.text);
                      if (context.mounted) showSnack(context, l.passwordResetSent);
                    }),
                    child: Text(l.forgotPassword),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
