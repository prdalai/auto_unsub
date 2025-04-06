import 'package:flutter/material.dart';
import '../../domain/entities/subscription.dart';
import '../theme/neomorphic_theme.dart';

class AddSubscriptionScreen extends StatefulWidget {
  final Function(Subscription) onSubscriptionAdded;

  const AddSubscriptionScreen({
    Key? key,
    required this.onSubscriptionAdded,
  }) : super(key: key);

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedBillingCycle = 'Monthly';
  final _nextBillingDateController = TextEditingController();

  final List<String> _billingCycles = [
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

  @override
  void dispose() {
    _serviceNameController.dispose();
    _amountController.dispose();
    _nextBillingDateController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final subscription = Subscription(
        serviceName: _serviceNameController.text,
        amount: double.parse(_amountController.text),
        billingCycle: _selectedBillingCycle,
        nextBillingDate: _nextBillingDateController.text,
        isActive: true,
        startDate: DateTime.now(),
      );

      widget.onSubscriptionAdded(subscription);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Subscription'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _serviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                  hintText: 'e.g., Netflix, Spotify',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a service name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'e.g., 15.99',
                  prefixText: '₹',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedBillingCycle,
                decoration: const InputDecoration(
                  labelText: 'Billing Cycle',
                ),
                items: _billingCycles.map((cycle) {
                  return DropdownMenuItem(
                    value: cycle,
                    child: Text(cycle),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedBillingCycle = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nextBillingDateController,
                decoration: const InputDecoration(
                  labelText: 'Next Billing Date',
                  hintText: 'YYYY-MM-DD',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the next billing date';
                  }
                  // TODO: Add date format validation
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Add Subscription'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
