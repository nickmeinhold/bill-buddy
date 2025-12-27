import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Screen displayed after signup showing recovery codes
/// User must acknowledge they've saved the codes before proceeding
class RecoveryCodesScreen extends StatefulWidget {
  final List<String> recoveryCodes;
  final VoidCallback onAcknowledged;

  const RecoveryCodesScreen({
    super.key,
    required this.recoveryCodes,
    required this.onAcknowledged,
  });

  @override
  State<RecoveryCodesScreen> createState() => _RecoveryCodesScreenState();
}

class _RecoveryCodesScreenState extends State<RecoveryCodesScreen> {
  bool _hasCopied = false;
  bool _hasAcknowledged = false;

  void _copyAllCodes() {
    final allCodes = widget.recoveryCodes.join('\n');
    Clipboard.setData(ClipboardData(text: allCodes));

    setState(() {
      _hasCopied = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery codes copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Your Recovery Codes'),
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Save these codes now! You will need them to recover your data if you forget your password.',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Recovery Codes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Each code can only be used once. Store them in a safe place.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: widget.recoveryCodes.map((code) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          child: Text(
                            code,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _copyAllCodes,
                      icon: Icon(_hasCopied ? Icons.check : Icons.copy),
                      label: Text(_hasCopied ? 'Copied!' : 'Copy All Codes'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _hasAcknowledged,
                onChanged: (value) {
                  setState(() {
                    _hasAcknowledged = value ?? false;
                  });
                },
                title: const Text(
                  'I have saved my recovery codes in a safe place',
                ),
                subtitle: const Text(
                  'I understand that without these codes, I cannot recover my data if I forget my password.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _hasAcknowledged ? widget.onAcknowledged : null,
                child: const Text('Continue to App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
