import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/encryption/encryption_provider.dart';
import '../domain/auth_provider.dart';
import 'encryption_passphrase_dialog.dart';
import 'recovery_codes_screen.dart';

/// Check if we should show Apple Sign In (iOS/macOS)
bool get _showAppleSignIn =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// Check if we should show Google Sign In (Android/Web)
bool get _showGoogleSignIn =>
    kIsWeb || defaultTargetPlatform == TargetPlatform.android;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await ref.read(authServiceProvider).signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // Unlock encryption with password
      if (credential.user != null) {
        try {
          await ref.read(encryptionProvider.notifier).unlockForUser(
                credential.user!.uid,
                _passwordController.text,
              );
        } catch (e) {
          // If encryption not set up yet (legacy user), initialize it
          debugPrint('Encryption unlock failed, initializing: $e');
          await ref.read(encryptionProvider.notifier).initializeForNewUser(
                credential.user!.uid,
                _passwordController.text,
              );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await ref.read(authServiceProvider).signInWithGoogle();

      if (credential.user != null && mounted) {
        await _handleSocialAuthEncryption(credential.user!.uid);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handle encryption setup/unlock for social auth users
  Future<void> _handleSocialAuthEncryption(String userId) async {
    // Check if user has encryption set up
    final hasEncryption =
        await ref.read(encryptionProvider.notifier).checkEncryptionStatus(userId);

    if (!hasEncryption) {
      // New user - prompt to set passphrase
      if (!mounted) return;
      final passphrase = await EncryptionPassphraseDialog.show(
        context,
        isNewUser: true,
      );

      if (passphrase == null) {
        // User cancelled - sign out
        await ref.read(authServiceProvider).signOut();
        return;
      }

      // Initialize encryption and show recovery codes
      final recoveryCodes = await ref
          .read(encryptionProvider.notifier)
          .initializeForNewUser(userId, passphrase);

      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RecoveryCodesScreen(
              recoveryCodes: recoveryCodes,
              onAcknowledged: () {
                Navigator.of(context).pop();
                context.go('/');
              },
            ),
          ),
        );
      }
    } else {
      // Existing user - prompt for passphrase
      if (!mounted) return;
      final passphrase = await EncryptionPassphraseDialog.show(
        context,
        isNewUser: false,
      );

      if (passphrase == null) {
        // User cancelled - sign out
        await ref.read(authServiceProvider).signOut();
        return;
      }

      try {
        await ref
            .read(encryptionProvider.notifier)
            .unlockForUser(userId, passphrase);
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Incorrect passphrase. Please try again.';
          });
        }
        // Sign out on wrong passphrase
        await ref.read(authServiceProvider).signOut();
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await ref.read(authServiceProvider).signInWithApple();

      if (credential.user != null && mounted) {
        await _handleSocialAuthEncryption(credential.user!.uid);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        var isLoading = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your email address and we\'ll send you a link to reset your password.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            await ref
                                .read(authServiceProvider)
                                .sendPasswordResetEmail(emailController.text.trim());
                            if (context.mounted) {
                              Navigator.pop(context, true);
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                              errorMessage = _getResetErrorMessage(e);
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Reset Link'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getResetErrorMessage(Object error) {
    final errorString = error.toString();
    if (errorString.contains('user-not-found')) {
      return 'No account found with this email.';
    } else if (errorString.contains('invalid-email')) {
      return 'Invalid email address.';
    } else if (errorString.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'Failed to send reset email. Please try again.';
  }

  String _getErrorMessage(Object error) {
    final errorString = error.toString();
    debugPrint('Auth error: $errorString');

    if (errorString.contains('user-not-found')) {
      return 'No account found with this email.';
    } else if (errorString.contains('wrong-password')) {
      return 'Incorrect password.';
    } else if (errorString.contains('invalid-credential')) {
      return 'Invalid email or password.';
    } else if (errorString.contains('invalid-email')) {
      return 'Invalid email address.';
    } else if (errorString.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    } else if (errorString.contains('network-request-failed')) {
      return 'Network error. Check your connection.';
    } else if (errorString.contains('user-disabled')) {
      return 'This account has been disabled.';
    } else if (errorString.contains('cancelled') ||
        errorString.contains('canceled')) {
      return 'Sign in was cancelled.';
    } else if (errorString.contains('AuthorizationError error 1000') ||
        errorString.contains('AuthorizationErrorCode.unknown')) {
      return 'Apple Sign In is not configured. Please enable it in Apple Developer Portal.';
    }
    // Show actual error for debugging
    return 'Error: $errorString';
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
      ],
    );
  }

  Widget _buildAppleSignInButton(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _signInWithApple,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: const Icon(Icons.apple, size: 24),
      label: const Text('Sign in with Apple'),
    );
  }

  Widget _buildGoogleSignInButton(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _signInWithGoogle,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Image.network(
        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
        height: 24,
        width: 24,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.g_mobiledata, size: 24),
      ),
      label: const Text('Sign in with Google'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bill Buddy',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your finances with ease',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signIn(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                  if (_showAppleSignIn || _showGoogleSignIn) ...[
                    const SizedBox(height: 24),
                    _buildDivider(theme),
                    const SizedBox(height: 24),
                    if (_showAppleSignIn) _buildAppleSignInButton(theme),
                    if (_showGoogleSignIn) _buildGoogleSignInButton(theme),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
