import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/account_model.dart';
import '../../accounts/domain/accounts_provider.dart';
import '../../../shared/models/statement_model.dart';
import '../domain/statements_provider.dart';

class StatementsScreen extends ConsumerStatefulWidget {
  const StatementsScreen({super.key});

  @override
  ConsumerState<StatementsScreen> createState() => _StatementsScreenState();
}

class _StatementsScreenState extends ConsumerState<StatementsScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    // ... code unchanged until _pickAndUploadFile ...
    final theme = Theme.of(context);
    final statementsAsync = ref.watch(statementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Import Statements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadFile,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.upload_file),
        label: Text(_isUploading ? 'Uploading...' : 'Upload PDF'),
      ),
      body: statementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (statements) {
          if (statements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No statements uploaded',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload a bank statement PDF to import transactions',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: statements.length,
            itemBuilder: (context, index) {
              final statement = statements[index];
              return _StatementCard(
                statement: statement,
                onDelete: () => _deleteStatement(statement),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not read file')));
        }
        return;
      }

      // Check for available accounts
      final accounts = await ref.read(accountsProvider.future);
      String? accountId;

      if (accounts.isNotEmpty && mounted) {
        accountId = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Select Account'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, null),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Unassigned'),
                ),
              ),
              ...accounts.map(
                (acc) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, acc.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance,
                          color: Color(acc.color),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(acc.name),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      setState(() => _isUploading = true);

      final service = ref.read(statementServiceProvider);
      await service.uploadStatement(
        fileName: file.name,
        fileBytes: file.bytes!,
        accountId: accountId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Statement uploaded! Processing will begin shortly.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deleteStatement(StatementModel statement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Statement'),
        content: Text(
          'Delete "${statement.fileName}"? This will not remove imported transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(statementServiceProvider);
        await service.deleteStatement(statement);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Statement deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }
}

class _StatementCard extends StatelessWidget {
  final StatementModel statement;
  final VoidCallback onDelete;

  const _StatementCard({required this.statement, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(
            statement.status,
          ).withValues(alpha: 0.1),
          child: Icon(
            _getStatusIcon(statement.status),
            color: _getStatusColor(statement.status),
          ),
        ),
        title: Text(
          statement.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateFormat.format(statement.uploadedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            _buildStatusChip(context),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final color = _getStatusColor(statement.status);
    String label;

    switch (statement.status) {
      case StatementStatus.uploading:
        label = 'Uploading...';
      case StatementStatus.processing:
        label = 'Processing...';
      case StatementStatus.completed:
        label = '${statement.transactionCount ?? 0} transactions imported';
      case StatementStatus.failed:
        label = statement.errorMessage ?? 'Failed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statement.status == StatementStatus.processing ||
              statement.status == StatementStatus.uploading)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
            ),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(StatementStatus status) {
    switch (status) {
      case StatementStatus.uploading:
        return Colors.blue;
      case StatementStatus.processing:
        return Colors.orange;
      case StatementStatus.completed:
        return Colors.green;
      case StatementStatus.failed:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(StatementStatus status) {
    switch (status) {
      case StatementStatus.uploading:
        return Icons.cloud_upload;
      case StatementStatus.processing:
        return Icons.hourglass_top;
      case StatementStatus.completed:
        return Icons.check_circle;
      case StatementStatus.failed:
        return Icons.error;
    }
  }
}
