class Environment {
  static const String apiEndpoint = String.fromEnvironment(
    'API_ENDPOINT',
    defaultValue: 'https://api.rabbithole.cred.club',
  );

  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'sk-3ToKZJ6ATqO4IR865zSGEA',
  );
}

// Usage example:
// flutter run --dart-define=API_ENDPOINT=https://api.rabbithole.cred.club --dart-define=API_KEY=your-api-key 