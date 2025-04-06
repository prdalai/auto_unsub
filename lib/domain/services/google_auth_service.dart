import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/auth_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  final GoogleSignIn _googleSignIn;
  final SharedPreferences _prefs;
  gmail.GmailApi? _gmailApi;

  GoogleAuthService({
    required SharedPreferences prefs,
    GoogleSignIn? googleSignIn,
  })  : _prefs = prefs,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [
                'email',
                'https://www.googleapis.com/auth/gmail.readonly',
              ],
            );

  Future<gmail.GmailApi?> getGmailApi() async {
    if (_gmailApi != null) return _gmailApi;

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      if (auth.accessToken == null) return null;

      final client = http.Client();
      final credentials = AccessCredentials(
        AccessToken(
          'Bearer',
          auth.accessToken!,
          DateTime.now().add(const Duration(hours: 1)),
        ),
        null, // No refresh token needed as we use GoogleSignIn
        [
          'email',
          'https://www.googleapis.com/auth/gmail.readonly',
        ],
      );

      final authClient = autoRefreshingClient(
        ClientId('', ''), // Not needed as we use GoogleSignIn
        credentials,
        client,
      );

      _gmailApi = gmail.GmailApi(authClient);
      return _gmailApi;
    } catch (e) {
      print('Error initializing Gmail API: $e');
      return null;
    }
  }

  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final auth = await account.authentication;
      _prefs.setString('google_access_token', auth.accessToken ?? '');
      _prefs.setString('google_id_token', auth.idToken ?? '');
      _prefs.setString('google_email', account.email);

      return true;
    } catch (e) {
      print('Error signing in with Google: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _prefs.remove('google_access_token');
      _prefs.remove('google_id_token');
      _prefs.remove('google_email');
      _gmailApi = null;
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  bool get isSignedIn => _googleSignIn.currentUser != null;
  String? get userEmail => _googleSignIn.currentUser?.email;
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
