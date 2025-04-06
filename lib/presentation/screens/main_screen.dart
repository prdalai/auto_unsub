import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/subscription.dart';
import '../../data/datasources/subscription_local_data_source.dart';
import '../../data/datasources/email_scanner.dart';
import '../../domain/services/subscription_ai_service.dart';
import '../../domain/services/google_auth_service.dart';
import 'subscription_list_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'dart:math';
import '../widgets/neomorphic_card.dart';

class MainScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final VoidCallback onThemeToggle;

  const MainScreen({
    Key? key,
    required this.prefs,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Subscription> _subscriptions = [];
  late final GoogleAuthService _googleAuthService;

  @override
  void initState() {
    super.initState();
    _googleAuthService = GoogleAuthService(prefs: widget.prefs);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final isAuthenticated = await _googleAuthService.signIn();
      if (isAuthenticated) {
        await _loadSubscriptions();
      } else {
        // If not authenticated, show sign-in UI
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please sign in to continue'),
              action: SnackBarAction(
                label: 'Sign In',
                onPressed: _handleSignIn,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing app: $e')),
        );
      }
    }
  }

  Future<void> _handleSignIn() async {
    try {
      final isAuthenticated = await _googleAuthService.signIn();
      if (isAuthenticated) {
        await _loadSubscriptions();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sign in')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing in: $e')),
        );
      }
    }
  }

  Future<void> _loadSubscriptions() async {
    // TODO: Implement actual subscription loading
    setState(() {
      _subscriptions.addAll(_generateDummySubscriptions());
    });
  }

  List<Subscription> _generateDummySubscriptions() {
    final now = DateTime.now();
    return [
      Subscription(
        id: '1',
        serviceName: 'YouTube Premium',
        amount: 129,
        billingCycle: 'monthly',
        nextBillingDate: '2025-04-18',
        category: 'Streaming',
        isActive: true,
        startDate: now.subtract(const Duration(days: 30)),
      ),
      Subscription(
        id: '2',
        serviceName: 'Spotify',
        amount: 119,
        billingCycle: 'monthly',
        nextBillingDate: '2025-05-03',
        category: 'Music',
        isActive: true,
        startDate: now.subtract(const Duration(days: 60)),
      ),
      Subscription(
        id: '3',
        serviceName: 'Netflix',
        amount: 499,
        billingCycle: 'monthly',
        nextBillingDate: '2025-05-07',
        category: 'Streaming',
        isActive: true,
        startDate: now.subtract(const Duration(days: 90)),
      ),
      Subscription(
        id: '4',
        serviceName: 'Google One',
        amount: 195,
        billingCycle: 'monthly',
        nextBillingDate: '2025-05-15',
        category: 'Cloud Storage',
        isActive: true,
        startDate: now.subtract(const Duration(days: 120)),
      ),
    ];
  }

  void _handleSubscriptionAdded(Subscription subscription) {
    setState(() {
      _subscriptions.add(subscription);
    });
  }

  void _handleSubscriptionUpdated(Subscription subscription) {
    setState(() {
      final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
      if (index != -1) {
        _subscriptions[index] = subscription;
      }
    });
  }

  void _handleSubscriptionDeleted(String id) {
    setState(() {
      _subscriptions.removeWhere((s) => s.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SubscriptionListScreen(
            subscriptions: _subscriptions,
            onSubscriptionAdded: _handleSubscriptionAdded,
            onSubscriptionUpdated: _handleSubscriptionUpdated,
            onSubscriptionDeleted: (subscription) =>
                _handleSubscriptionDeleted(subscription.id),
            isLoading: false,
            error: null,
          ),
          AnalyticsScreen(subscriptions: _subscriptions),
          SettingsScreen(
            onThemeToggle: widget.onThemeToggle,
            onSignOut: () async {
              await _googleAuthService.signOut();
              if (mounted) {
                _handleSignIn();
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: NeomorphicCard(
        isInset: true,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.subscriptions),
              label: 'Subscriptions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client;

  GoogleAuthClient(this._accessToken, this._client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }
}
