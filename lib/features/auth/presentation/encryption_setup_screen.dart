import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/encryption/encryption_provider.dart';
import '../../../routing/app_router.dart';
import '../domain/auth_provider.dart';
import 'encryption_passphrase_dialog.dart';

/// Screen shown when a user needs to set up or unlock encryption
class EncryptionSetupScreen extends ConsumerStatefulWidget {
  const EncryptionSetupScreen({super.key});

  @override
  ConsumerState<EncryptionSetupScreen> createState() =>
      _EncryptionSetupScreenState();
}

class _EncryptionSetupScreenState extends ConsumerState<EncryptionSetupScreen> {
  bool _isLoading = true;
  bool _needsSetup = false;
  String? _errorMessage;
  bool _hasStartedSetup = false;

  @override
  void initState() {
    super.initState();
    // Delay to ensure widget is fully built before showing dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasStartedSetup) {
        _hasStartedSetup = true;
        _checkEncryptionStatus();
      }
    });
  }

  Future<void> _checkEncryptionStatus() async {
    debugPrint('ENCRYPTION_SETUP: Starting check...');
    if (!mounted) {
      debugPrint('ENCRYPTION_SETUP: Not mounted, returning');
      return;
    }

    // Check if already unlocked (e.g., email/password login already unlocked it)
    final currentState = ref.read(encryptionProvider);
    if (currentState.isUnlocked) {
      debugPrint('ENCRYPTION_SETUP: Already unlocked, going to dashboard');
      context.go('/dashboard');
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      debugPrint('ENCRYPTION_SETUP: No user, going to login');
      context.go('/login');
      return;
    }

    debugPrint('ENCRYPTION_SETUP: Checking encryption for user ${user.uid}');
    try {
      final hasEncryption = await ref
          .read(encryptionProvider.notifier)
          .checkEncryptionStatus(user.uid);

      debugPrint('ENCRYPTION_SETUP: hasEncryption=$hasEncryption');
      if (!mounted) {
        debugPrint('ENCRYPTION_SETUP: Not mounted after check, returning');
        return;
      }

      setState(() {
        _isLoading = false;
        _needsSetup = !hasEncryption;
      });

      debugPrint('ENCRYPTION_SETUP: Prompting for passphrase, isNewUser=${!hasEncryption}');
      if (hasEncryption) {
        // Existing user - prompt for passphrase
        await _promptForPassphrase(user.uid, isNewUser: false);
      } else {
        // New user - prompt to create passphrase
        await _promptForPassphrase(user.uid, isNewUser: true);
      }
    } catch (e) {
      debugPrint('ENCRYPTION_SETUP: Error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error checking encryption status: $e';
      });
    }
  }

  Future<void> _promptForPassphrase(String userId,
      {required bool isNewUser}) async {
    debugPrint('ENCRYPTION_SETUP: Showing passphrase dialog...');
    final passphrase = await EncryptionPassphraseDialog.show(
      context,
      isNewUser: isNewUser,
    );
    debugPrint('ENCRYPTION_SETUP: Dialog returned, passphrase=${passphrase != null ? "provided" : "null"}');

    if (passphrase == null) {
      debugPrint('ENCRYPTION_SETUP: User cancelled, signing out');
      // User cancelled - sign out
      await ref.read(authServiceProvider).signOut();
      if (mounted) context.go('/login');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isNewUser) {
        // Initialize encryption and show recovery codes
        final recoveryCodes = await ref
            .read(encryptionProvider.notifier)
            .initializeForNewUser(userId, passphrase);

        if (mounted) {
          ref.read(pendingRecoveryCodesProvider.notifier).state = recoveryCodes;
          context.go('/recovery-codes');
        }
      } else {
        // Unlock existing encryption
        await ref
            .read(encryptionProvider.notifier)
            .unlockForUser(userId, passphrase);

        if (mounted) {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = isNewUser
            ? 'Error setting up encryption: $e'
            : 'Incorrect passphrase. Please try again.';
      });

      // If unlock failed, prompt again
      if (!isNewUser) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          await _promptForPassphrase(userId, isNewUser: false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                if (!_isLoading) ...[
                  Text(
                    _needsSetup ? 'Secure Your Data' : 'Unlock Your Data',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _needsSetup
                        ? 'Set up a passphrase to encrypt your financial data. Only you will be able to access it.'
                        : 'Enter your passphrase to decrypt your data.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                if (_isLoading)
                  const CircularProgressIndicator()
                else if (_errorMessage != null)
                  Column(
                    children: [
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
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _checkEncryptionStatus,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
