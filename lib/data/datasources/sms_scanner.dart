import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/services/subscription_ai_service.dart';

class SmsScanner {
  final SmsQuery _query = SmsQuery();
  final SubscriptionAIService _aiService;

  SmsScanner(this._aiService);

  Future<bool> requestPermissions() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<List<Subscription>> scanMessages() async {
    try {
      // Query all SMS messages without specifying a kind
      final messages = await _query.querySms(
        count: 100,
      );

      final subscriptions = <Subscription>[];

      for (var message in messages) {
        // Extract subscription details using AI
        final details = await _extractSubscriptionDetails(message);
        if (details != null) {
          subscriptions.add(details);
        }
      }

      return subscriptions;
    } catch (e) {
      print('Error scanning SMS: $e');
      return [];
    }
  }

  Future<Subscription?> _extractSubscriptionDetails(SmsMessage message) async {
    try {
      // Use AI service to extract subscription details from SMS body
      return await _aiService.extractSubscriptionDetails(message.body ?? '');
    } catch (e) {
      print('Error extracting subscription details from SMS: $e');
      return null;
    }
  }
}
