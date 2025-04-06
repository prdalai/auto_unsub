import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SIHHubAuthService {
  final FlutterSecureStorage _storage;
  final http.Client _client;

  SIHHubAuthService({
    required FlutterSecureStorage storage,
    required http.Client client,
  })  : _storage = storage,
        _client = client;

  static Future<SIHHubAuthService> create() async {
    final storage = const FlutterSecureStorage();
    final client = http.Client();
    return SIHHubAuthService(storage: storage, client: client);
  }

  Future<void> saveCredentials({
    required String bankType,
    required String username,
    required String password,
  }) async {
    final key = 'sih_hub_${bankType}_credentials';
    final credentials = {
      'username': username,
      'password': password,
    };
    await _storage.write(key: key, value: jsonEncode(credentials));
  }

  Future<Map<String, String>?> getCredentials(String bankType) async {
    final key = 'sih_hub_${bankType}_credentials';
    final credentialsJson = await _storage.read(key: key);
    if (credentialsJson == null) return null;

    final credentials = jsonDecode(credentialsJson) as Map<String, dynamic>;
    return {
      'username': credentials['username'] as String,
      'password': credentials['password'] as String,
    };
  }

  Future<bool> automateLogin(String bankType) async {
    try {
      final credentials = await getCredentials(bankType);
      if (credentials == null) return false;

      // Get the login page
      final loginUrl = _getLoginUrl(bankType);
      final loginResponse = await _client.get(Uri.parse(loginUrl));

      if (loginResponse.statusCode != 200) return false;

      // Extract CSRF token and other necessary form data
      final csrfToken = _extractCsrfToken(loginResponse.body);

      // Submit login form
      final loginData = {
        'username': credentials['username'],
        'password': credentials['password'],
        if (csrfToken != null) 'csrf_token': csrfToken,
      };

      final loginResult = await _client.post(
        Uri.parse(loginUrl),
        body: loginData,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        },
      );

      // Check if login was successful
      return _isLoginSuccessful(loginResult);
    } catch (e) {
      print('Error during login automation: $e');
      return false;
    }
  }

  /// Returns JavaScript code to automate login in the WebView
  String getLoginAutomationScript(
      String bankType, String username, String password) {
    // Different banks may have different login form structures
    switch (bankType) {
      case 'kotak':
        return '''
          (function() {
            try {
              console.log('Starting automation script...');
              console.log('Current URL:', window.location.href);
              console.log('Document ready state:', document.readyState);
              
              // First check if we're on the landing page
              if (window.location.href.includes('/landing')) {
                console.log('On landing page, looking for continue button...');
                
                // Function to find button by text content
                function findButtonByText(text) {
                  const elements = document.querySelectorAll('button, input[type="button"], input[type="submit"], a.btn');
                  console.log('Found ' + elements.length + ' potential button elements');
                  
                  for (const element of elements) {
                    const buttonText = (element.textContent || element.value || '').toLowerCase().trim();
                    console.log('Checking element:', {
                      tagName: element.tagName,
                      text: buttonText,
                      className: element.className,
                      id: element.id,
                      type: element.type,
                      isVisible: element.offsetParent !== null
                    });
                    
                    if (buttonText.includes(text.toLowerCase())) {
                      return element;
                    }
                  }
                  return null;
                }

                // Wait for the page to be fully loaded
                if (document.readyState !== 'complete') {
                  console.log('Page not fully loaded, waiting...');
                  setTimeout(() => {
                    console.log('Retrying after page load...');
                    window.location.reload();
                  }, 2000);
                  return true;
                }

                // Try to find the continue button
                let continueButton = null;
                
                // Try by class names first
                const classSelectors = [
                  '.continue-btn',
                  '.btn-continue',
                  '.btn-primary',
                  '.primary-btn',
                  'button[type="submit"]'
                ];
                
                for (const selector of classSelectors) {
                  const element = document.querySelector(selector);
                  if (element) {
                    console.log('Found element by selector:', selector, {
                      text: element.textContent,
                      isVisible: element.offsetParent !== null
                    });
                    if (element.offsetParent !== null) {  // Check if visible
                      continueButton = element;
                      break;
                    }
                  }
                }
                
                // If not found by class, try by text content
                if (!continueButton) {
                  console.log('Trying to find button by text content...');
                  continueButton = findButtonByText('continue') || 
                                 findButtonByText('proceed') || 
                                 findButtonByText('next');
                }

                // If still not found, try getting all buttons
                if (!continueButton) {
                  console.log('Button not found by normal means, dumping all buttons:');
                  const allButtons = document.getElementsByTagName('button');
                  for (let i = 0; i < allButtons.length; i++) {
                    const btn = allButtons[i];
                    console.log('Button ' + i + ':', {
                      text: btn.textContent,
                      className: btn.className,
                      id: btn.id,
                      type: btn.type,
                      isVisible: btn.offsetParent !== null
                    });
                  }
                }

                if (continueButton) {
                  console.log('Found continue button:', {
                    tagName: continueButton.tagName,
                    text: continueButton.textContent || continueButton.value,
                    className: continueButton.className,
                    id: continueButton.id,
                    isVisible: continueButton.offsetParent !== null
                  });
                  
                  // Try multiple ways to trigger the button
                  try {
                    // 1. Direct click
                    continueButton.click();
                    console.log('Direct click executed');
                    
                    // 2. Dispatch click event
                    const clickEvent = new MouseEvent('click', {
                      bubbles: true,
                      cancelable: true,
                      view: window
                    });
                    continueButton.dispatchEvent(clickEvent);
                    console.log('Click event dispatched');
                    
                    // 3. Form submit if available
                    if (continueButton.form) {
                      continueButton.form.submit();
                      console.log('Form submitted');
                    }
                    
                    return true;
                  } catch (clickError) {
                    console.error('Error clicking button:', clickError);
                    return false;
                  }
                } else {
                  console.log('Continue button not found');
                  return false;
                }
              }
              
              return false;
            } catch (e) {
              console.error('Automation error:', e);
              return false;
            }
          })();
        ''';

      case 'hdfc':
        // Similar script for HDFC Bank
        return '''
          (function() {
            try {
              // First check if we're on the landing page
              const buttons = Array.from(document.getElementsByTagName('button'));
              const continueButton = buttons.find(button => {
                const buttonText = button.textContent || button.innerText;
                return buttonText.trim().toLowerCase() === 'continue';
              });
              
              if (continueButton) {
                console.log('Found continue button, clicking it...');
                continueButton.click();
                return true;
              }

              // If we're on the login page, handle the login form
              const inputs = Array.from(document.getElementsByTagName('input'));
              const usernameField = inputs.find(input => 
                (input.type === 'text' || input.type === 'email') && 
                (input.placeholder || '').toLowerCase().includes('user')
              );
              const passwordField = inputs.find(input => input.type === 'password');
              const loginButton = document.querySelector('button[type="submit"]') || 
                                Array.from(document.getElementsByTagName('button')).find(btn => 
                                  (btn.textContent || '').toLowerCase().includes('sign in') || 
                                  (btn.textContent || '').toLowerCase().includes('login')
                                );
              
              if (usernameField && passwordField && loginButton) {
                console.log('Found login form elements...');
                
                // Fill in the credentials
                usernameField.value = '$username';
                passwordField.value = '$password';
                
                // Trigger input events
                usernameField.dispatchEvent(new Event('input', { bubbles: true }));
                passwordField.dispatchEvent(new Event('input', { bubbles: true }));
                usernameField.dispatchEvent(new Event('change', { bubbles: true }));
                passwordField.dispatchEvent(new Event('change', { bubbles: true }));
                
                // Handle reCAPTCHA if present
                const recaptcha = document.querySelector('iframe[src*="recaptcha"]');
                if (!recaptcha) {
                  console.log('No reCAPTCHA found, proceeding with login...');
                  setTimeout(() => {
                    loginButton.click();
                    console.log('Clicked login button');
                  }, 500);
                } else {
                  console.log('reCAPTCHA found, waiting for user interaction...');
                }
              } else {
                console.log('Login form elements not found:', {
                  usernameField: !!usernameField,
                  passwordField: !!passwordField,
                  loginButton: !!loginButton
                });
              }
              
              return true;
            } catch (e) {
              console.error('Login automation error:', e);
              return false;
            }
          })();
        ''';

      default:
        // Generic script for other banks
        return '''
          (function() {
            try {
              // First check if we're on the landing page
              const buttons = Array.from(document.getElementsByTagName('button'));
              const continueButton = buttons.find(button => {
                const buttonText = button.textContent || button.innerText;
                return buttonText.trim().toLowerCase() === 'continue';
              });
              
              if (continueButton) {
                console.log('Found continue button, clicking it...');
                continueButton.click();
                return true;
              }

              // If we're on the login page, handle the login form
              const inputs = Array.from(document.getElementsByTagName('input'));
              const usernameField = inputs.find(input => 
                (input.type === 'text' || input.type === 'email') && 
                (input.placeholder || '').toLowerCase().includes('user')
              );
              const passwordField = inputs.find(input => input.type === 'password');
              const loginButton = document.querySelector('button[type="submit"]') || 
                                Array.from(document.getElementsByTagName('button')).find(btn => 
                                  (btn.textContent || '').toLowerCase().includes('sign in') || 
                                  (btn.textContent || '').toLowerCase().includes('login')
                                );
              
              if (usernameField && passwordField && loginButton) {
                console.log('Found login form elements...');
                
                // Fill in the credentials
                usernameField.value = '$username';
                passwordField.value = '$password';
                
                // Trigger input events
                usernameField.dispatchEvent(new Event('input', { bubbles: true }));
                passwordField.dispatchEvent(new Event('input', { bubbles: true }));
                usernameField.dispatchEvent(new Event('change', { bubbles: true }));
                passwordField.dispatchEvent(new Event('change', { bubbles: true }));
                
                // Handle reCAPTCHA if present
                const recaptcha = document.querySelector('iframe[src*="recaptcha"]');
                if (!recaptcha) {
                  console.log('No reCAPTCHA found, proceeding with login...');
                  setTimeout(() => {
                    loginButton.click();
                    console.log('Clicked login button');
                  }, 500);
                } else {
                  console.log('reCAPTCHA found, waiting for user interaction...');
                }
              } else {
                console.log('Login form elements not found:', {
                  usernameField: !!usernameField,
                  passwordField: !!passwordField,
                  loginButton: !!loginButton
                });
              }
              
              return true;
            } catch (e) {
              console.error('Login automation error:', e);
              return false;
            }
          })();
        ''';
    }
  }

  String _getLoginUrl(String bankType) {
    final baseUrls = {
      'kotak': 'https://www.sihub.in/managesi/kotak/#/login',
      'hdfc': 'https://www.sihub.in/managesi/hdfcbank#/login',
      'sbi': 'https://www.sihub.in/managesi/sbi#/login',
    };
    return baseUrls[bankType] ?? '';
  }

  String? _extractCsrfToken(String html) {
    // Implement CSRF token extraction logic
    // This will depend on the specific structure of the login page
    return null;
  }

  bool _isLoginSuccessful(http.Response response) {
    // Implement login success detection logic
    // This will depend on the specific response patterns
    return response.statusCode == 200 &&
        !response.body.toLowerCase().contains('login') &&
        !response.body.toLowerCase().contains('error');
  }
}
