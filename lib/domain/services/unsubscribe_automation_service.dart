import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import 'email_scanning_service.dart';
import 'google_auth_service.dart';

class UnsubscribeAutomationService {
  final http.Client _client;

  UnsubscribeAutomationService({
    required http.Client client,
  }) : _client = client;

  static Future<UnsubscribeAutomationService> create() async {
    final client = http.Client();
    return UnsubscribeAutomationService(client: client);
  }

  // Get bank info for web view
  Map<String, dynamic>? getBankInfoForWebView(String bankType) {
    final bankName = _getBankName(bankType);
    final landingPageUrl = _getSIHHubBankLandingPage(bankType);

    if (bankName == null || landingPageUrl == null) return null;

    return {
      'bankName': bankName,
      'url': landingPageUrl,
      'bankType': bankType,
    };
  }

  String? _getBankName(String bankType) {
    // Map of bank types to their display names
    final bankNames = {
      'hdfc': 'HDFC Bank',
      'kotak': 'Kotak Bank',
      'sbi': 'State Bank of India',
    };

    return bankNames[bankType];
  }

  String? _getSIHHubBankLandingPage(String bankType) {
    // Map of bank types to their landing page URLs
    final bankLandingPages = {
      'hdfc': 'https://www.sihub.in/managesi/hdfcbank#/home/landing',
      'kotak': 'https://www.sihub.in/managesi/kotak/#/home/landing',
      'sbi': 'https://www.sihub.in/managesi/sbi#/home/landing',
    };

    return bankLandingPages[bankType];
  }
}
