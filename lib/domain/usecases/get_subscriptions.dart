import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';

class GetSubscriptions {
  final SubscriptionRepository repository;

  GetSubscriptions(this.repository);

  Future<List<Subscription>> call() async {
    return await repository.getSubscriptions();
  }
}
