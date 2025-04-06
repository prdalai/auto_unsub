import 'package:flutter/material.dart';
import '../../domain/models/subscription.dart';
import 'package:intl/intl.dart';

class SubscriptionDetailsScreen extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionDetailsScreen({
    Key? key,
    required this.subscription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subscription.serviceName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildDetailSection(
              context,
              title: 'Subscription Details',
              children: [
                _buildDetailItem('Service', subscription.serviceName),
                _buildDetailItem(
                    'Amount', '₹${subscription.amount.toStringAsFixed(2)}'),
                _buildDetailItem('Billing Cycle', subscription.billingCycle),
                _buildDetailItem(
                    'Next Billing Date', subscription.formattedNextBillingDate),
                _buildDetailItem(
                    'Status', subscription.isActive ? 'Active' : 'Inactive'),
                _buildDetailItem('Start Date',
                    DateFormat('MMM d, yyyy').format(subscription.startDate)),
                if (subscription.endDate != null)
                  _buildDetailItem('End Date',
                      DateFormat('MMM d, yyyy').format(subscription.endDate!)),
                if (subscription.category != null)
                  _buildDetailItem('Category', subscription.category!),
                if (subscription.paymentMethod != null)
                  _buildDetailItem(
                      'Payment Method', subscription.paymentMethod!),
              ],
            ),
            if (subscription.description != null ||
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
                    _buildDetailItem('Description', subscription.description!),
                  if (subscription.website != null)
                    _buildDetailItem('Website', subscription.website!),
                  if (subscription.email != null)
                    _buildDetailItem('Email', subscription.email!),
                  if (subscription.phone != null)
                    _buildDetailItem('Phone', subscription.phone!),
                  if (subscription.notes != null)
                    _buildDetailItem('Notes', subscription.notes!),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getServiceIcon(subscription.serviceName),
              color: Theme.of(context).colorScheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.serviceName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (subscription.category != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subscription.category!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.7),
                        ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '₹${subscription.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('netflix')) return Icons.movie;
    if (name.contains('youtube')) return Icons.play_circle;
    if (name.contains('disney')) return Icons.movie_creation;
    if (name.contains('spotify')) return Icons.music_note;
    if (name.contains('apple')) return Icons.apple;
    if (name.contains('google')) return Icons.g_mobiledata;
    if (name.contains('icloud')) return Icons.cloud;
    if (name.contains('xbox')) return Icons.games;
    if (name.contains('playstation')) return Icons.games;
    if (name.contains('microsoft')) return Icons.computer;
    if (name.contains('adobe')) return Icons.brush;
    return Icons.subscriptions;
  }
}
