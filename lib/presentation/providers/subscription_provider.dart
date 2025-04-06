import 'package:flutter/foundation.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/usecases/get_subscriptions.dart';

class SubscriptionProvider extends ChangeNotifier {
  final GetSubscriptions getSubscriptions;
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;
  String? _error;

  SubscriptionProvider(this.getSubscriptions);

  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSubscriptions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _subscriptions = await getSubscriptions();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
