class Subscription {
  final String id;
  final String serviceName;
  final double amount;
  final String billingCycle;
  final String nextBillingDate;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final String? category;
  final String? description;
  final String? email;
  final String? website;
  final String? phone;
  final String? notes;
  final String? paymentMethod;

  Subscription({
    required this.id,
    required this.serviceName,
    required this.amount,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.isActive,
    required this.startDate,
    this.endDate,
    this.category,
    this.description,
    this.email,
    this.website,
    this.phone,
    this.notes,
    this.paymentMethod,
  });

  String get formattedNextBillingDate {
    try {
      final date = DateTime.parse(nextBillingDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return nextBillingDate;
    }
  }
}
