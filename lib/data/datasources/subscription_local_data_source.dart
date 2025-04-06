import '../../domain/entities/subscription.dart';
import 'email_scanner.dart';

class SubscriptionLocalDataSource {
  final EmailScanner _emailScanner;
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;
  String? _error;

  SubscriptionLocalDataSource(this._emailScanner);

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<List<Subscription>> getSubscriptions() async {
    try {
      _isLoading = true;
      _error = null;

      // Request Gmail permissions
      final hasPermission = await _emailScanner.requestPermissions();
      if (!hasPermission) {
        _error = 'Gmail access permission denied';
        return [];
      }

      // Scan Gmail for subscriptions
      _subscriptions = await _emailScanner.scanEmails();
      return _subscriptions;
    } catch (e) {
      _error = 'Error scanning emails: $e';
      print(_error);
      return [];
    } finally {
      _isLoading = false;
    }
  }

  Future<void> addSubscription(Subscription subscription) async {
    _subscriptions.add(subscription);
  }

  Future<void> updateSubscription(Subscription subscription) async {
    final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
    if (index != -1) {
      _subscriptions[index] = subscription;
    }
  }

  Future<void> deleteSubscription(String id) async {
    _subscriptions.removeWhere((s) => s.id == id);
  }

  Future<void> toggleSubscriptionStatus(String id) async {
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index != -1) {
      final subscription = _subscriptions[index];
      _subscriptions[index] = subscription.copyWith(
        isActive: !subscription.isActive,
      );
    }
  }
}
