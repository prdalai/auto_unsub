import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/subscription.dart';
import '../theme/neomorphic_theme.dart';

class AddSubscriptionDialog extends StatefulWidget {
  final Function(Subscription) onSubscriptionAdded;

  const AddSubscriptionDialog({
    Key? key,
    required this.onSubscriptionAdded,
  }) : super(key: key);

  @override
  State<AddSubscriptionDialog> createState() => _AddSubscriptionDialogState();
}

class _AddSubscriptionDialogState extends State<AddSubscriptionDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _websiteController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String _billingCycle = 'Monthly';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isActive = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: NeomorphicTheme.neomorphicDecoration(
                  borderRadius: 20,
                  blurRadius: 20,
                  offset: 10,
                  isDark: isDark,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Add Subscription',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildNeomorphicTextField(
                          context: context,
                          controller: _nameController,
                          labelText: 'Service Name',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildNeomorphicTextField(
                          context: context,
                          controller: _amountController,
                          labelText: 'Amount (₹)',
                          prefixText: '₹ ',
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
                        _buildNeomorphicDropdown(
                          context: context,
                          value: _billingCycle,
                          items: ['Weekly', 'Monthly', 'Quarterly', 'Yearly']
                              .map((cycle) => DropdownMenuItem(
                                    value: cycle,
                                    child: Text(cycle),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _billingCycle = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: TextEditingController(
                                  text: _startDate.toString().split(' ')[0],
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                ),
                                readOnly: true,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _startDate = date;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: TextEditingController(
                                  text:
                                      _endDate?.toString().split(' ')[0] ?? '',
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'End Date (Optional)',
                                ),
                                readOnly: true,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _endDate = date;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Active'),
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Enter description',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Category (Optional)',
                            hintText: 'Enter category',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _websiteController,
                          decoration: const InputDecoration(
                            labelText: 'Website (Optional)',
                            hintText: 'Enter website URL',
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email (Optional)',
                            hintText: 'Enter email',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone (Optional)',
                            hintText: 'Enter phone number',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            hintText: 'Enter notes',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildNeomorphicButton(
                              context: context,
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 16),
                            _buildNeomorphicButton(
                              context: context,
                              onPressed: _handleSubmit,
                              child: const Text('Add'),
                              isPrimary: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNeomorphicTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    String? prefixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: NeomorphicTheme.neomorphicDecoration(
        borderRadius: 10,
        blurRadius: 10,
        offset: 5,
        isDark: isDark,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          prefixText: prefixText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark
              ? NeomorphicTheme.darkBackgroundColor
              : NeomorphicTheme.lightBackgroundColor,
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildNeomorphicDropdown({
    required BuildContext context,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: NeomorphicTheme.neomorphicDecoration(
        borderRadius: 10,
        blurRadius: 10,
        offset: 5,
        isDark: isDark,
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: 'Billing Cycle',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark
              ? NeomorphicTheme.darkBackgroundColor
              : NeomorphicTheme.lightBackgroundColor,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNeomorphicButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required Widget child,
    bool isPrimary = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: isPrimary
            ? NeomorphicTheme.neomorphicButtonDecoration(
                borderRadius: 10,
                blurRadius: 10,
                offset: 5,
                isDark: isDark,
              )
            : NeomorphicTheme.neomorphicDecoration(
                borderRadius: 10,
                blurRadius: 10,
                offset: 5,
                isDark: isDark,
              ),
        child: Text(
          (child as Text).data!,
          style: TextStyle(
            color: isPrimary
                ? NeomorphicTheme.lightColor
                : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final subscription = Subscription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        serviceName: _nameController.text,
        amount: double.parse(_amountController.text),
        billingCycle: _billingCycle,
        nextBillingDate:
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        category:
            _categoryController.text.isEmpty ? null : _categoryController.text,
        website:
            _websiteController.text.isEmpty ? null : _websiteController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      widget.onSubscriptionAdded(subscription);
      Navigator.pop(context);
    }
  }
}
