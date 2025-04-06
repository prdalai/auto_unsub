import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import 'google_auth_service.dart';

class EmailScanningService {
  final GoogleAuthService _googleAuthService;
  final SharedPreferences _prefs;
  gmail.GmailApi? _gmailApi;

  // Common subscription-related keywords
  static const _subscriptionKeywords = [
    'subscription',
    'receipt',
    'invoice',
    'payment',
    'renewal',
    'billing',
    'membership',
    'plan',
    'premium',
    'pro',
    'unlimited',
    'welcome',
    'confirmation',
    'activated',
    'started',
  ];

  // Known OTT and cloud service domains
  static const _knownServices = {
    'sihhub.com': 'SIH Hub',
    'sihub.in': 'SIH Hub',
    'netflix.com': 'Netflix',
    'primevideo.com': 'Amazon Prime',
    'disneyplus.com': 'Disney+',
    'hbomax.com': 'HBO Max',
    'hulu.com': 'Hulu',
    'apple.com': 'Apple One',
    'spotify.com': 'Spotify',
    'youtube.com': 'YouTube Premium',
    'google.com': 'Google One',
    'microsoft.com': 'Microsoft 365',
    'dropbox.com': 'Dropbox',
    'icloud.com': 'iCloud+',
    'amazon.com': 'Amazon Prime',
    'aws.amazon.com': 'AWS',
    'cloud.google.com': 'Google Cloud',
    'azure.microsoft.com': 'Azure',
    'salesforce.com': 'Salesforce',
    'adobe.com': 'Adobe Creative Cloud',
    'zoom.us': 'Zoom',
    'slack.com': 'Slack',
    'github.com': 'GitHub',
    'gitlab.com': 'GitLab',
    'bitbucket.org': 'Bitbucket',
    'notion.so': 'Notion',
    'figma.com': 'Figma',
    'canva.com': 'Canva Pro',
    'mailchimp.com': 'Mailchimp',
    'shopify.com': 'Shopify',
    'wix.com': 'Wix',
    'squarespace.com': 'Squarespace',
  };

  // Known Indian banks for SIH Hub
  static const _knownBanks = {
    'hdfc': 'HDFC Bank',
    'kotak': 'Kotak Bank',
    'sbi': 'State Bank of India',
  };

  // Date patterns to look for in emails
  static final _datePatterns = [
    RegExp(
        r'(?:start|begin|activation|subscription) (?:date|from):\s*([A-Za-z]+\s+\d{1,2},?\s+\d{4})'),
    RegExp(
        r'(?:renewal|next billing|next payment) (?:date|on):\s*([A-Za-z]+\s+\d{1,2},?\s+\d{4})'),
    RegExp(
        r'(?:expiry|end|expiration) (?:date|on):\s*([A-Za-z]+\s+\d{1,2},?\s+\d{4})'),
    RegExp(r'(\d{1,2}\s+[A-Za-z]+\s+\d{4})'),
  ];

  EmailScanningService({
    required GoogleAuthService googleAuthService,
    required SharedPreferences prefs,
  })  : _googleAuthService = googleAuthService,
        _prefs = prefs;

  Future<void> initialize() async {
    if (_gmailApi != null) return;

    final gmailApi = await _googleAuthService.getGmailApi();
    if (gmailApi == null) {
      throw Exception('Failed to initialize Gmail API');
    }
    _gmailApi = gmailApi;
  }

  Future<List<EmailMessage>> scanEmails() async {
    if (_gmailApi == null) {
      await initialize();
    }

    try {
      // Search for emails with subscription-related keywords
      final query = _subscriptionKeywords
          .map((keyword) => 'subject:$keyword')
          .join(' OR ');
      final response = await _gmailApi!.users.messages.list(
        'me',
        q: query,
        maxResults: 500,
      );

      final messages = response.messages ?? [];
      final emailMessages = <EmailMessage>[];

      for (final message in messages) {
        final email = await _gmailApi!.users.messages.get('me', message.id!);
        emailMessages.add(EmailMessage.fromGmailMessage(email));
      }

      return emailMessages;
    } catch (e) {
      print('Error scanning emails: $e');
      return [];
    }
  }

  Future<String> getEmailBody(String messageId) async {
    if (_gmailApi == null) {
      await initialize();
    }

    try {
      final email = await _gmailApi!.users.messages.get('me', messageId);
      return _getEmailBody(email);
    } catch (e) {
      print('Error getting email body: $e');
      return '';
    }
  }

  Future<List<Subscription>> scanEmailsForSubscriptions() async {
    try {
      await initialize();

      // Search for emails with subscription-related keywords
      final query = _subscriptionKeywords
          .map((keyword) => 'subject:$keyword')
          .join(' OR ');
      final messages = await _gmailApi!.users.messages.list(
        'me',
        q: query,
        maxResults: 500, // Increased to scan more emails
      );

      final subscriptions = <Subscription>[];
      final processedSenders = <String>{};

      for (var message in messages.messages ?? []) {
        final email = await _gmailApi!.users.messages.get('me', message.id!);
        final headers = email.payload?.headers ?? [];

        final from = headers
                .firstWhere((h) => h.name?.toLowerCase() == 'from',
                    orElse: () => gmail.MessagePartHeader())
                .value ??
            '';

        // Skip if we've already processed this sender
        if (processedSenders.contains(from)) continue;
        processedSenders.add(from);

        final subject = headers
                .firstWhere((h) => h.name?.toLowerCase() == 'subject',
                    orElse: () => gmail.MessagePartHeader())
                .value ??
            '';

        // Extract subscription details using AI
        final subscription = await _extractSubscriptionDetails(email);

        if (subscription != null) {
          subscriptions.add(subscription);
        }
      }

      return subscriptions;
    } catch (e) {
      print('Error scanning emails: $e');
      return [];
    }
  }

  String _getEmailBody(gmail.Message email) {
    if (email.payload?.body?.data != null) {
      return email.payload!.body!.data!;
    }

    final parts = email.payload?.parts ?? [];
    for (var part in parts) {
      if (part.mimeType == 'text/plain') {
        return part.body?.data ?? '';
      }
    }
    return '';
  }

  DateTime _getEmailDate(gmail.Message email) {
    final headers = email.payload?.headers ?? [];
    final dateHeader = headers
        .firstWhere((h) => h.name?.toLowerCase() == 'date',
            orElse: () => gmail.MessagePartHeader())
        .value;

    if (dateHeader != null) {
      try {
        return DateTime.parse(dateHeader);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    return DateTime.now();
  }

  Future<Subscription?> _extractSubscriptionDetails(gmail.Message email) async {
    try {
      final body = _getEmailBody(email);
      final from = _getEmailBody(email);

      // Extract service name from email address
      final serviceName = _getKnownServiceName(from);

      // Extract amount
      final amount = _extractAmount(body);

      // Extract billing cycle
      final billingCycle = _extractBillingCycle(body);

      // Extract next billing date
      final nextBillingDate = _extractNextBillingDate(body);

      // Special handling for SIH Hub
      if (serviceName == 'SIH Hub') {
        // Extract bank information from email body
        final bankInfo = _extractBankInfo(body);

        return Subscription(
          id: email.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          serviceName: 'SIH Hub',
          amount: amount ?? 0.0,
          billingCycle: billingCycle ?? 'monthly',
          nextBillingDate: nextBillingDate ??
              DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          isActive: true,
          startDate: DateTime.now(),
          category: 'Banking',
          description: bankInfo != null
              ? 'SIH Hub subscription for ${bankInfo}'
              : 'SIH Hub subscription service',
          email: _extractEmailFromBody(body),
        );
      }

      if (serviceName != null && amount != null) {
        return Subscription(
          id: email.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          serviceName: serviceName,
          amount: amount,
          billingCycle: billingCycle ?? 'monthly',
          nextBillingDate: nextBillingDate ??
              DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          isActive: true,
          startDate: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error extracting subscription details: $e');
    }
    return null;
  }

  String? _getKnownServiceName(String from) {
    for (var entry in _knownServices.entries) {
      if (from.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  double? _extractAmount(String body) {
    // Look for common price patterns
    final pricePattern = RegExp(r'\$?\d+(?:\.\d{2})?');
    final matches = pricePattern.allMatches(body);

    for (var match in matches) {
      final price = double.tryParse(match.group(0)?.replaceAll('\$', '') ?? '');
      if (price != null && price > 0) {
        return price;
      }
    }
    return null;
  }

  String _extractBillingCycle(String body) {
    final bodyLower = body.toLowerCase();
    if (bodyLower.contains('yearly') || bodyLower.contains('annual')) {
      return 'Yearly';
    } else if (bodyLower.contains('monthly')) {
      return 'Monthly';
    } else if (bodyLower.contains('quarterly')) {
      return 'Quarterly';
    } else if (bodyLower.contains('weekly')) {
      return 'Weekly';
    }
    return 'Monthly'; // Default to monthly if not specified
  }

  DateTime _extractDate(String body, DateTime emailDate,
      {required bool isStartDate}) {
    // Try to find date in the email body
    for (var pattern in _datePatterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        final dateStr = match.group(1);
        if (dateStr != null) {
          try {
            // Try different date formats
            final formats = [
              'MMMM d, yyyy',
              'MMMM d yyyy',
              'MMM d, yyyy',
              'MMM d yyyy',
              'd MMMM yyyy',
              'd MMM yyyy',
              'yyyy-MM-dd',
              'MM/dd/yyyy',
              'dd/MM/yyyy',
            ];

            for (var format in formats) {
              try {
                final date = DateFormat(format).parse(dateStr);
                return date;
              } catch (e) {
                // Try next format
              }
            }
          } catch (e) {
            print('Error parsing date: $e');
          }
        }
      }
    }

    // If no date found, use email date as fallback
    if (isStartDate) {
      return emailDate;
    } else {
      // For end date, add 1 month to email date as fallback
      return emailDate.add(const Duration(days: 30));
    }
  }

  bool _determineSubscriptionStatus(String body, DateTime? endDate) {
    final bodyLower = body.toLowerCase();

    // Check for cancellation or expiry
    if (bodyLower.contains('cancelled') ||
        bodyLower.contains('canceled') ||
        bodyLower.contains('expired') ||
        bodyLower.contains('terminated')) {
      return false;
    }

    // Check if end date is in the past
    if (endDate != null && endDate.isBefore(DateTime.now())) {
      return false;
    }

    return true;
  }

  String _extractNextBillingDate(String body) {
    // Implementation of _extractNextBillingDate method
    // This method should return a string representation of the next billing date
    // based on the provided body.
    // For now, we'll return a placeholder string.
    return DateTime.now().add(const Duration(days: 30)).toIso8601String();
  }

  String? _extractEmailFromBody(String body) {
    // Look for email patterns in the body
    final emailPattern = RegExp(r'[\w\.-]+@[\w\.-]+\.\w+');
    final match = emailPattern.firstMatch(body);
    if (match != null) {
      return match.group(0);
    }
    return null;
  }

  String? _extractBankInfo(String body) {
    final bodyLower = body.toLowerCase();

    // Check for bank names in the email body
    for (final entry in _knownBanks.entries) {
      if (bodyLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Check for bank-specific URLs
    if (bodyLower.contains('sihub.in/managesi/hdfcbank')) {
      return 'HDFC Bank';
    } else if (bodyLower.contains('sihub.in/managesi/kotak')) {
      return 'Kotak Bank';
    } else if (bodyLower.contains('sihub.in/managesi/sbi')) {
      return 'State Bank of India';
    }

    return null;
  }
}

class EmailMessage {
  final String id;
  final Map<String, String> headers;
  final String? body;

  EmailMessage({
    required this.id,
    required this.headers,
    this.body,
  });

  String get serviceName {
    final from = headers['From'] ?? '';
    // Use a simple approach to extract service name from email address
    final emailParts = from.split('@');
    if (emailParts.length > 1) {
      final domain = emailParts[1].toLowerCase();
      if (domain.contains('sihhub.com')) return 'SIH Hub';
      if (domain.contains('netflix.com')) return 'Netflix';
      if (domain.contains('spotify.com')) return 'Spotify';
      if (domain.contains('youtube.com')) return 'YouTube Premium';
      // Add more services as needed
    }
    return from;
  }

  factory EmailMessage.fromGmailMessage(gmail.Message message) {
    final headers = <String, String>{};
    for (final header in message.payload?.headers ?? []) {
      if (header.name != null && header.value != null) {
        headers[header.name!] = header.value!;
      }
    }

    String? body;
    if (message.payload?.body?.data != null) {
      body = message.payload!.body!.data;
    } else if (message.payload?.parts != null) {
      for (final part in message.payload!.parts!) {
        if (part.mimeType == 'text/plain') {
          body = part.body?.data;
          break;
        }
      }
    }

    return EmailMessage(
      id: message.id!,
      headers: headers,
      body: body,
    );
  }
}
