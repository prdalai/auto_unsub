import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/subscription.dart';
import '../../domain/services/unsubscribe_automation_service.dart';
import '../widgets/subscription_card.dart';
import '../widgets/add_subscription_dialog.dart';
import '../screens/subscription_details_screen.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import '../widgets/neomorphic_card.dart';
import 'sih_hub_web_view_screen.dart';

class SubscriptionListScreen extends StatefulWidget {
  final List<Subscription> subscriptions;
  final Function(Subscription) onSubscriptionAdded;
  final Function(Subscription) onSubscriptionUpdated;
  final Function(Subscription) onSubscriptionDeleted;
  final bool isLoading;
  final String? error;

  const SubscriptionListScreen({
    Key? key,
    required this.subscriptions,
    required this.onSubscriptionAdded,
    required this.onSubscriptionUpdated,
    required this.onSubscriptionDeleted,
    this.isLoading = false,
    this.error,
  }) : super(key: key);

  @override
  State<SubscriptionListScreen> createState() => _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends State<SubscriptionListScreen> {
  UnsubscribeAutomationService? _unsubscribeService;
  bool _isUnsubscribing = false;

  @override
  void initState() {
    super.initState();
    _initializeUnsubscribeService();
  }

  Future<void> _initializeUnsubscribeService() async {
    _unsubscribeService = await UnsubscribeAutomationService.create();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showInfoDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSubscriptionDialog(context),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning your emails for subscriptions...'),
          ],
        ),
      );
    }

    if (widget.error != null) {
            return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${widget.error}',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement retry functionality
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (widget.subscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.subscriptions_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No subscriptions yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.5),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first subscription',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.5),
                  ),
            ),
          ],
        ),
            );
          }

          return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.subscriptions.length,
            itemBuilder: (context, index) {
        final subscription = widget.subscriptions[index];
        return NeomorphicCard(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      subscription.serviceName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.serviceName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          subscription.category ?? 'Uncategorized',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () =>
                            _showSubscriptionDetails(context, subscription),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Unsubscribe'),
                        onPressed: () =>
                            _showUnsubscribeDialog(context, subscription),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                        ),
                        Text(
                          '₹${subscription.amount.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
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
                          'Next Billing',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                        ),
                        Text(
                          subscription.formattedNextBillingDate,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (subscription.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  subscription.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ],
          ),
              );
            },
          );
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddSubscriptionDialog(
        onSubscriptionAdded: widget.onSubscriptionAdded,
      ),
    );
  }

  void _showSubscriptionDetails(
      BuildContext context, Subscription subscription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subscription.serviceName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailSection(
                  context,
                  title: 'Subscription Details',
                  children: [
                    _buildDetailRow(
                      context,
                      label: 'Amount',
                      value: '₹${subscription.amount.toStringAsFixed(2)}',
                    ),
                    _buildDetailRow(
                      context,
                      label: 'Billing Cycle',
                      value: subscription.billingCycle,
                    ),
                    _buildDetailRow(
                      context,
                      label: 'Status',
                      value: subscription.isActive ? 'Active' : 'Inactive',
                      valueColor: subscription.isActive
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),
                    _buildDetailRow(
                      context,
                      label: 'Start Date',
                      value: DateFormat('MMM d, yyyy')
                          .format(subscription.startDate),
                    ),
                    if (subscription.endDate != null)
                      _buildDetailRow(
                        context,
                        label: 'End Date',
                        value: DateFormat('MMM d, yyyy')
                            .format(subscription.endDate!),
                      ),
                  ],
                ),
                if (subscription.description != null ||
                    subscription.category != null ||
                    subscription.website != null ||
                    subscription.email != null ||
                    subscription.phone != null ||
                    subscription.notes != null) ...[
                  const SizedBox(height: 24),
                  _buildDetailSection(
                    context,
                    title: 'Additional Information',
                    children: [
                      if (subscription.description != null)
                        _buildDetailRow(
                          context,
                          label: 'Description',
                          value: subscription.description!,
                        ),
                      if (subscription.category != null)
                        _buildDetailRow(
                          context,
                          label: 'Category',
                          value: subscription.category!,
                        ),
                      if (subscription.website != null)
                        _buildDetailRow(
                          context,
                          label: 'Website',
                          value: subscription.website!,
                          isLink: true,
                        ),
                      if (subscription.email != null)
                        _buildDetailRow(
                          context,
                          label: 'Email',
                          value: subscription.email!,
                          isLink: true,
                        ),
                      if (subscription.phone != null)
                        _buildDetailRow(
                          context,
                          label: 'Phone',
                          value: subscription.phone!,
                          isLink: true,
                        ),
                      if (subscription.notes != null)
                        _buildDetailRow(
                          context,
                          label: 'Notes',
                          value: subscription.notes!,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement unsubscribe functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Unsubscribe'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUnsubscribeDialog(BuildContext context, Subscription subscription) {
    // Always show the bank selection dialog when unsubscribe is clicked
    _showSIHHubBankSelectionDialog(context);
  }

  void _showSIHHubBankSelectionDialog(BuildContext context) {
    String? selectedBank;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Your Bank'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please select your bank to proceed with SIH Hub:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedBank,
                decoration: const InputDecoration(
                  labelText: 'Bank',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'hdfc',
                    child: Text('HDFC Bank'),
                  ),
                  DropdownMenuItem(
                    value: 'kotak',
                    child: Text('Kotak Bank'),
                  ),
                  DropdownMenuItem(
                    value: 'sbi',
                    child: Text('State Bank of India'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedBank = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedBank == null
                  ? null
                  : () {
                      Navigator.pop(context);

                      // Get bank info for web view
                      final bankInfo = _unsubscribeService
                          ?.getBankInfoForWebView(selectedBank!);

                      if (bankInfo != null) {
                        final bankType = bankInfo['bankType'] as String?;
                        if (bankType != null) {
                          // Open the web view with the bank's SIH Hub page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SIHHubWebViewScreen(
                                bankType: bankType,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Invalid bank type. Please try again.'),
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      } else {
                        // Show an error message if bank info couldn't be determined
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Could not determine bank information. Please try again.'),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isLink = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor ??
                        (isLink
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface),
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Subscriptions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(context, 'Active Subscriptions',
                '${widget.subscriptions.where((s) => s.isActive).length}'),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'Total Monthly Spending',
                '₹${_calculateTotalMonthlySpending().toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'Most Expensive',
                _getMostExpensiveSubscription()?.serviceName ?? 'N/A'),
            const SizedBox(height: 16),
            Text(
              'Categories',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._getCategoryBreakdown().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${e.key}: ${e.value} subscriptions',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  double _calculateTotalMonthlySpending() {
    return widget.subscriptions.fold(0.0, (total, subscription) {
      if (!subscription.isActive) return total;

      final monthlyAmount = switch (subscription.billingCycle.toLowerCase()) {
        'monthly' => subscription.amount,
        'quarterly' => subscription.amount / 3,
        'yearly' => subscription.amount / 12,
        'weekly' => subscription.amount * 4,
        _ => subscription.amount,
      };

      return total + monthlyAmount;
    });
  }

  Subscription? _getMostExpensiveSubscription() {
    if (widget.subscriptions.isEmpty) return null;

    return widget.subscriptions.reduce((a, b) {
      final aMonthly = _getMonthlyAmount(a);
      final bMonthly = _getMonthlyAmount(b);
      return aMonthly > bMonthly ? a : b;
    });
  }

  double _getMonthlyAmount(Subscription subscription) {
    return switch (subscription.billingCycle.toLowerCase()) {
      'monthly' => subscription.amount,
      'quarterly' => subscription.amount / 3,
      'yearly' => subscription.amount / 12,
      'weekly' => subscription.amount * 4,
      _ => subscription.amount,
    };
  }

  Map<String, int> _getCategoryBreakdown() {
    final breakdown = <String, int>{};
    for (final subscription in widget.subscriptions) {
      final category = subscription.category ?? 'Uncategorized';
      breakdown[category] = (breakdown[category] ?? 0) + 1;
    }
    return Map.fromEntries(
        breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }
}
