import 'package:flutter/material.dart';

/// Dialog for setting or entering encryption passphrase for social auth users
class EncryptionPassphraseDialog extends StatefulWidget {
  /// Whether this is a new user setting up encryption (true) or
  /// an existing user entering their passphrase (false)
  final bool isNewUser;

  const EncryptionPassphraseDialog({super.key, required this.isNewUser});

  /// Shows the dialog and returns the passphrase if submitted, null if cancelled
  static Future<String?> show(BuildContext context, {required bool isNewUser}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EncryptionPassphraseDialog(isNewUser: isNewUser),
    );
  }

  @override
  State<EncryptionPassphraseDialog> createState() =>
      _EncryptionPassphraseDialogState();
}

class _EncryptionPassphraseDialogState
    extends State<EncryptionPassphraseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passphraseController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassphrase = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_passphraseController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.isNewUser ? 'Set Encryption Passphrase' : 'Enter Passphrase',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isNewUser) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This passphrase encrypts your financial data. It is separate from your social login.',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Text(
                  'Enter your encryption passphrase to access your data.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _passphraseController,
                obscureText: _obscurePassphrase,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Passphrase',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassphrase
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassphrase = !_obscurePassphrase;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a passphrase';
                  }
                  if (widget.isNewUser && value.length < 8) {
                    return 'Passphrase must be at least 8 characters';
                  }
                  return null;
                },
              ),
              if (widget.isNewUser) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Passphrase',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passphraseController.text) {
                      return 'Passphrases do not match';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.isNewUser ? 'Set Passphrase' : 'Unlock'),
        ),
      ],
    );
  }
}
