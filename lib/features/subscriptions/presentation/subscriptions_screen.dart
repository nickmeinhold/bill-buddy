import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/subscription_model.dart';
import '../domain/subscriptions_provider.dart';
import 'subscription_form_screen.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subscriptionsAsync = ref.watch(subscriptionsProvider);

    return subscriptionsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (subscriptions) {
        final activeSubscriptions = subscriptions
            .where((s) => s.status == SubscriptionStatus.active)
            .toList();
        final totalMonthly = activeSubscriptions.fold<double>(
          0,
          (sum, sub) => sum + sub.monthlyAmount,
        );
        final totalYearly = activeSubscriptions.fold<double>(
          0,
          (sum, sub) => sum + sub.yearlyAmount,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Subscriptions'),
            actions: [
              IconButton(icon: const Icon(Icons.sort), onPressed: () {}),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showSubscriptionForm(context),
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              // Summary card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.subscriptionColor,
                      AppTheme.subscriptionColor.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Cost',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '\$${totalMonthly.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Yearly Cost',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '\$${totalYearly.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.subscriptions,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${activeSubscriptions.length} active subscriptions',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Subscriptions list
              Expanded(
                child: subscriptions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.subscriptions_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No subscriptions yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add your first subscription',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: subscriptions.length,
                        itemBuilder: (context, index) {
                          final sub = subscriptions[index];
                          return _SubscriptionCard(
                            subscription: sub,
                            onTap: () => _showSubscriptionForm(context, sub),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubscriptionForm(
    BuildContext context, [
    SubscriptionModel? subscription,
  ]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            SubscriptionFormScreen(subscription: subscription),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionModel subscription;
  final VoidCallback? onTap;

  const _SubscriptionCard({required this.subscription, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysUntil = subscription.nextBillingDate
        .difference(DateTime.now())
        .inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.subscriptionColor.withValues(alpha: 0.1),
          child: const Icon(
            Icons.subscriptions,
            color: AppTheme.subscriptionColor,
          ),
        ),
        title: Text(subscription.name),
        subtitle: Text(
          '${subscription.category} • Renews in $daysUntil days',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${subscription.amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '/${subscription.frequency.name}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
