import 'package:flutter/material.dart';
import '../widgets/neomorphic_card.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final VoidCallback? onSignOut;

  const SettingsScreen({
    Key? key,
    required this.onThemeToggle,
    this.onSignOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NeomorphicCard(
            child: ListTile(
              leading: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                isDark ? 'Dark Mode' : 'Light Mode',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: Switch(
                value: isDark,
                onChanged: (_) => onThemeToggle(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (onSignOut != null)
            NeomorphicCard(
              child: ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Sign Out',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                onTap: onSignOut,
              ),
            ),
          const SizedBox(height: 16),
          NeomorphicCard(
            child: ListTile(
              leading: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'About',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                'Auto Unsub v1.0.0',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
