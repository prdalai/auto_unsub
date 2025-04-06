import 'package:permission_handler/permission_handler.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import '../../domain/entities/subscription.dart';
import '../../domain/services/subscription_ai_service.dart';

class EmailScanner {
  final gmail.GmailApi _gmailApi;
  final SubscriptionAIService _aiService;
  final GoogleSignIn _googleSignIn;

  // Specific subject lines to filter
  final Map<String, String> _targetSubscriptions = {
    'Welcome to YouTube Premium': 'YouTube Premium',
    'Thanks for joining Netflix': 'Netflix',
  };

  EmailScanner(this._gmailApi, this._aiService)
      : _googleSignIn = GoogleSignIn(
          scopes: [
            'email',
            'https://www.googleapis.com/auth/gmail.readonly',
          ],
        );

  Future<bool> requestPermissions() async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        return false;
      }

      final account = await _googleSignIn.signIn();
      if (account == null) {
        return false;
      }

      final auth = await account.authentication;
      if (auth.accessToken == null) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  Future<List<Subscription>> scanEmails() async {
    try {
      if (!await requestPermissions()) {
        throw Exception('Gmail authentication failed');
      }

      final subscriptions = <Subscription>[];
      final processedServices = <String>{};

      // Search for each specific subject line
      for (var subject in _targetSubscriptions.keys) {
        final messages = await _gmailApi.users.messages.list(
          'me',
          q: 'subject:"$subject"',
          maxResults: 10, // Limit to most recent emails
        );

        for (var message in messages.messages ?? []) {
          final email = await _gmailApi.users.messages.get(
            'me',
            message.id!,
          );

          final subscription = await _extractSubscriptionDetails(
            email,
            _targetSubscriptions[subject]!,
          );

          if (subscription != null &&
              !processedServices.contains(subscription.serviceName)) {
            subscriptions.add(subscription);
            processedServices.add(subscription.serviceName);
          }
        }
      }

      return subscriptions;
    } catch (e) {
      print('Error scanning emails: $e');
      rethrow;
    }
  }

  Future<Subscription?> _extractSubscriptionDetails(
    gmail.Message email,
    String serviceName,
  ) async {
    try {
      final payload = email.payload;
      if (payload == null) return null;

      // Get email body
      String body = '';
      if (payload.body != null && payload.body!.data != null) {
        body = utf8.decode(base64Url.decode(payload.body!.data!));
      } else if (payload.parts != null) {
        for (var part in payload.parts!) {
          if (part.mimeType == 'text/plain' && part.body?.data != null) {
            body = utf8.decode(base64Url.decode(part.body!.data!));
            break;
          }
        }
      }

      if (body.isEmpty) return null;

      // Extract headers
      final headers = payload.headers ?? [];
      final dateStr = headers
              .firstWhere(
                (header) => header.name?.toLowerCase() == 'date',
                orElse: () => gmail.MessagePartHeader(name: '', value: ''),
              )
              .value ??
          '';

      // Parse email date
      DateTime emailDate;
      try {
        emailDate = _parseEmailDate(dateStr);
      } catch (e) {
        emailDate = DateTime.now();
      }

      // Extract order date from email content
      DateTime? orderDate = _extractOrderDate(body);
      if (orderDate == null) {
        orderDate = emailDate;
      }

      print(
          'Order date: ${orderDate.day} ${_getMonthName(orderDate.month)} ${orderDate.year}');

      // Use AI service to extract subscription details
      final aiSubscription = await _aiService.extractSubscriptionDetails(body);

      // Calculate current billing cycle date based on order date and AI insights
      DateTime currentBillingDate =
          _calculateCurrentBillingDate(orderDate, aiSubscription);

      // Extract amount based on service
      double? amount;
      if (serviceName == 'Netflix') {
        amount = _extractNetflixAmount(body);
      } else if (serviceName == 'YouTube Premium') {
        amount = _extractYouTubeAmount(body);
      }

      if (amount == null) return null;

      // Extract payment method
      final paymentMethod = _extractPaymentMethod(body);

      // Get current date
      final now = DateTime.now();
      print('Current date: ${now.day} ${_getMonthName(now.month)} ${now.year}');

      // Use the current month for the next billing date
      // Take the day from order date, use current month, and current year
      DateTime nextBillingDate = DateTime(
        now.year,
        now.month, // Use current month
        orderDate.day, // Day from order date
      );

      // Format next billing date with month name and year
      final nextMonthName = _getMonthName(nextBillingDate.month);
      final formattedNextBillingDate =
          '${nextBillingDate.day} $nextMonthName ${nextBillingDate.year}';
      print('Next billing date: $formattedNextBillingDate');

      // Create subscription
      return Subscription(
        serviceName: serviceName,
        amount: amount,
        billingCycle:
            'monthly', // Both Netflix and YouTube are typically monthly
        nextBillingDate: nextBillingDate.toIso8601String(),
        isActive: true,
        startDate: orderDate,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      print('Error extracting subscription details: $e');
      return null;
    }
  }

  DateTime _calculateCurrentBillingDate(
      DateTime orderDate, Subscription? aiSubscription) {
    // Get current date
    final now = DateTime.now();

    // If AI service provided a subscription with next billing date, use it
    if (aiSubscription != null && aiSubscription.nextBillingDate != null) {
      try {
        final aiDate = DateTime.parse(aiSubscription.nextBillingDate!);
        // If the AI date is in the future, use it
        if (aiDate.isAfter(now)) {
          return aiDate;
        }
      } catch (e) {
        print('Error parsing AI next billing date: $e');
      }
    }

    // Take the day from the order date, use current month and year
    final currentBillingDate = DateTime(
      now.year, // Current year
      now.month, // Current month
      orderDate.day, // Day from order date
    );

    // Format the date with month name and year
    final monthName = _getMonthName(currentBillingDate.month);
    print(
        'Current billing date: ${currentBillingDate.day} $monthName ${currentBillingDate.year}');

    return currentBillingDate;
  }

  DateTime? _extractOrderDate(String body) {
    // Common date patterns in emails
    final datePatterns = [
      RegExp(r'Order Date\s*([A-Za-z]+\s+\d{1,2},\s+\d{4})',
          caseSensitive: false),
      RegExp(r'Order date\s*([A-Za-z]+\s+\d{1,2},\s+\d{4})',
          caseSensitive: false),
      RegExp(r'Date of Order\s*([A-Za-z]+\s+\d{1,2},\s+\d{4})',
          caseSensitive: false),
      RegExp(r'Subscription Date\s*([A-Za-z]+\s+\d{1,2},\s+\d{4})',
          caseSensitive: false),
      RegExp(r'Start Date\s*([A-Za-z]+\s+\d{1,2},\s+\d{4})',
          caseSensitive: false),
      RegExp(r'Billing Date\s*([A-Za-z]+\s+\d{1,2},\s+\d{4})',
          caseSensitive: false),
    ];

    for (var pattern in datePatterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        final dateStr = match.group(1)!;
        try {
          // Parse date in format "Sep 18, 2024"
          final parts = dateStr.split(' ');
          if (parts.length == 3) {
            final month = _getMonthNumber(parts[0]);
            final day = int.parse(parts[1].replaceAll(',', ''));
            final year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        } catch (e) {
          print('Error parsing order date: $e');
        }
      }
    }

    return null;
  }

  int _getMonthNumber(String monthName) {
    final months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12
    };

    final monthLower = monthName.toLowerCase().substring(0, 3);
    return months[monthLower] ?? 1;
  }

  String _getMonthName(int monthNumber) {
    final months = {
      1: 'January',
      2: 'February',
      3: 'March',
      4: 'April',
      5: 'May',
      6: 'June',
      7: 'July',
      8: 'August',
      9: 'September',
      10: 'October',
      11: 'November',
      12: 'December'
    };

    return months[monthNumber] ?? 'January';
  }

  double? _extractNetflixAmount(String body) {
    final patterns = [
      RegExp(r'(?:INR|Rs\.|₹)\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'\$\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'charged.*?(?:INR|Rs\.|₹)\s*(\d+(?:\.\d{2})?)',
          caseSensitive: false),
      RegExp(r'charged.*?\$\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        final amount = double.tryParse(match.group(1)!);
        if (amount != null && amount > 0) {
          // If the pattern contains $, convert to rupees (assuming 1 USD = 83 INR)
          if (pattern.pattern.contains('\$')) {
            return amount * 83;
          }
          return amount;
        }
      }
    }
    return null;
  }

  double? _extractYouTubeAmount(String body) {
    final patterns = [
      RegExp(r'(?:INR|Rs\.|₹)\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'\$\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'amount.*?(?:INR|Rs\.|₹)\s*(\d+(?:\.\d{2})?)',
          caseSensitive: false),
      RegExp(r'amount.*?\$\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'charged.*?(?:INR|Rs\.|₹)\s*(\d+(?:\.\d{2})?)',
          caseSensitive: false),
      RegExp(r'charged.*?\$\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        final amount = double.tryParse(match.group(1)!);
        if (amount != null && amount > 0) {
          // If the pattern contains $, convert to rupees (assuming 1 USD = 83 INR)
          if (pattern.pattern.contains('\$')) {
            return amount * 83;
          }
          return amount;
        }
      }
    }
    return null;
  }

  String? _extractPaymentMethod(String text) {
    final patterns = [
      RegExp(r'paid (?:with|using) (?:your )?([A-Za-z\s]+(?:card|account))'),
      RegExp(r'charged to (?:your )?([A-Za-z\s]+(?:card|account))'),
      RegExp(r'payment method:?\s*([A-Za-z\s]+(?:card|account))'),
      RegExp(r'([A-Za-z\s]+(?:card|account)) ending in \d{4}'),
      RegExp(r'UPI transaction ID', caseSensitive: false),
      RegExp(r'UPI payment', caseSensitive: false),
      RegExp(r'UPI ID', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        if (pattern.pattern.contains('UPI')) {
          return 'UPI Payment';
        }
        if (match.groupCount >= 1) {
          final method = match.group(1)?.trim();
          if (method != null && method.isNotEmpty) {
            return method;
          }
        }
      }
    }

    return null;
  }

  DateTime _parseEmailDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        final cleanDate = dateStr
            .replaceAll(RegExp(r'\([^)]*\)'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        return DateTime.parse(cleanDate);
      } catch (e) {
        return DateTime.now();
      }
    }
  }
}
