import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_local_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionLocalDataSource localDataSource;

  SubscriptionRepositoryImpl(this.localDataSource);

  @override
  Future<List<Subscription>> getSubscriptions() async {
    return localDataSource.getSubscriptions();
  }

  @override
  Future<void> addSubscription(Subscription subscription) async {
    await localDataSource.addSubscription(subscription);
  }

  @override
  Future<void> updateSubscription(Subscription subscription) async {
    await localDataSource.updateSubscription(subscription);
  }

  @override
  Future<void> deleteSubscription(String id) async {
    await localDataSource.deleteSubscription(id);
  }

  @override
  Future<void> toggleSubscriptionStatus(String id) async {
    await localDataSource.toggleSubscriptionStatus(id);
  }
}
