import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/account_model.dart';
import '../domain/accounts_provider.dart';
import 'account_form_screen.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountForm(context),
        child: const Icon(Icons.add),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('No accounts added yet'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _showAccountForm(context),
                    child: const Text('Add your first account'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(
                      account.color,
                    ).withValues(alpha: 0.1),
                    child: Icon(
                      Icons.account_balance, // Default icon for now
                      color: Color(account.color),
                    ),
                  ),
                  title: Text(account.name),
                  subtitle: Text(account.type.name.toUpperCase()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAccountForm(context, account),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAccountForm(BuildContext context, [AccountModel? account]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccountFormScreen(account: account),
      ),
    );
  }
}
