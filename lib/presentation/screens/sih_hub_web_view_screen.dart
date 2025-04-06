import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import '../../domain/services/sih_hub_auth_service.dart';
import '../../domain/services/replicate_api_service.dart';
import '../widgets/sih_hub_credentials_dialog.dart';

class SIHHubWebViewScreen extends StatefulWidget {
  final String bankType;

  const SIHHubWebViewScreen({
    Key? key,
    required this.bankType,
  }) : super(key: key);

  @override
  State<SIHHubWebViewScreen> createState() => _SIHHubWebViewScreenState();
}

class _SIHHubWebViewScreenState extends State<SIHHubWebViewScreen> {
  late final WebViewController _controller;
  late final SIHHubAuthService _authService;
  // final ReplicateApiService _replicateService = ReplicateApiService();
  Timer? _automationTimer;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  bool _hasShownCredentialsDialog = false;

  // Guidance overlay state
  bool _showGuidance = false;
  String _guidanceText = '';
  Timer? _guidanceTimer;

  // Step tracking
  int _currentStep = 0;
  final List<String> _steps = [
    'Login to your bank account',
    'Navigate to the "All Bills" section',
    'View your subscriptions',
    'Manage your subscriptions'
  ];

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _initializeAuthService();
  }

  @override
  void dispose() {
    _automationTimer?.cancel();
    _guidanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page started loading: $url');
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: _onPageFinished,
          onWebResourceError: (WebResourceError error) {
            print('Web resource error: ${error.description}');
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request: ${request.url}');
            // Allow all navigation
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'consoleLog',
        onMessageReceived: (JavaScriptMessage message) {
          print('JavaScript console: ${message.message}');
        },
      )
      ..addJavaScriptChannel(
        'showGuidance',
        onMessageReceived: (JavaScriptMessage message) {
          _showGuidanceOverlay(message.message);
        },
      )
      ..addJavaScriptChannel(
        'updateStep',
        onMessageReceived: (JavaScriptMessage message) {
          final stepIndex = int.tryParse(message.message);
          if (stepIndex != null &&
              stepIndex >= 0 &&
              stepIndex < _steps.length) {
            setState(() {
              _currentStep = stepIndex;
            });
          }
        },
      )
      ..loadRequest(Uri.parse(_getInitialUrl()));
  }

  Future<void> _initializeAuthService() async {
    _authService = await SIHHubAuthService.create();
  }

  String _getInitialUrl() {
    switch (widget.bankType) {
      case 'kotak':
        return 'https://www.sihub.in/managesi/kotak/#/home/login';
      case 'hdfc':
        return 'https://www.sihub.in/managesi/hdfcbank#/home/landing';
      case 'sbi':
        return 'https://www.sihub.in/managesi/sbi#/home/landing';
      default:
        return 'https://www.sihub.in/managesi/kotak/#/home/landing';
    }
  }

  void _startAutomation() {
    _automationTimer?.cancel();
    _automationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _automateInteractions();
    });
  }

  Future<void> _automateInteractions() async {
    try {
      // Inject the automation script
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          function findClickableElement() {
            // Helper function to check if an element is visible
            function isVisible(element) {
              return !!(element.offsetWidth || element.offsetHeight || element.getClientRects().length);
            }
            
            // Helper function to get element text
            function getText(element) {
              return (element.textContent || element.innerText || element.value || '').toLowerCase().trim();
            }
            
            // List of text to look for
            const targetTexts = ['continue', 'next', 'proceed', 'submit', 'confirm'];
            
            // List of selectors to try
            const selectors = [
              'button',
              'input[type="submit"]',
              'input[type="button"]',
              'a.btn',
              '[role="button"]',
              '.btn',
              '.button'
            ];
            
            // Try each selector
            for (const selector of selectors) {
              const elements = document.querySelectorAll(selector);
              console.log('Checking selector:', selector, 'Found:', elements.length, 'elements');
              
              for (const element of elements) {
                if (!isVisible(element)) continue;
                
                const text = getText(element);
                console.log('Element:', {
                  tag: element.tagName,
                  text: text,
                  class: element.className,
                  type: element.type,
                  role: element.getAttribute('role')
                });
                
                if (targetTexts.some(target => text.includes(target))) {
                  return element;
                }
              }
            }
            
            // Try finding by aria-label
            const ariaElements = document.querySelectorAll('[aria-label]');
            for (const element of ariaElements) {
              if (!isVisible(element)) continue;
              
              const ariaLabel = element.getAttribute('aria-label').toLowerCase();
              if (targetTexts.some(target => ariaLabel.includes(target))) {
                return element;
              }
            }
            
            return null;
          }
          
          const element = findClickableElement();
          if (element) {
            console.log('Found clickable element:', {
              tag: element.tagName,
              text: element.textContent || element.value,
              class: element.className
            });
            
            // Try multiple ways to trigger the element
            try {
              element.click();
              console.log('Direct click successful');
              
              // If it's a form element, try submitting the form
              if (element.form) {
                element.form.submit();
                console.log('Form submitted');
              }
              
              return true;
            } catch (e) {
              console.error('Click error:', e);
              return false;
            }
          }
          
          console.log('No clickable element found');
          return false;
        })();
      ''');

      print('Automation result: $result');

      if (result.toString() == 'true') {
        // Successfully clicked something, wait a bit longer before next attempt
        _automationTimer?.cancel();
        _automationTimer = Timer.periodic(const Duration(seconds: 4), (_) {
          _automateInteractions();
        });
      }
    } catch (e) {
      print('Error during automation: $e');
    }
  }

  Future<void> _attemptContinue() async {
    print('Attempting to click continue button...');

    final credentials = await _authService.getCredentials(widget.bankType);
    if (credentials == null) {
      print('No credentials found, showing dialog...');
      // If no credentials are saved, show the dialog now
      await _showCredentialsDialog();
      return;
    }

    final script = _authService.getLoginAutomationScript(
      widget.bankType,
      credentials['username']!,
      credentials['password']!,
    );

    try {
      print('Running automation script...');
      final result = await _controller.runJavaScriptReturningResult(script);
      print('Automation script completed with result: $result');

      // If the script returned false, show the credentials dialog
      if (result.toString() == 'false') {
        print('Automation failed, showing credentials dialog...');
        await _showCredentialsDialog();
      }
    } catch (e) {
      print('Error during continue automation: $e');
      // On error, show the credentials dialog
      await _showCredentialsDialog();
    }
  }

  Future<void> _showCredentialsDialog() async {
    print('Showing credentials dialog...');
    setState(() {
      _hasShownCredentialsDialog = true;
      _currentStep = 0; // Reset to first step
    });

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SIHHubCredentialsDialog(bankType: widget.bankType),
    );

    print('Credentials dialog result: $result');
    if (result == true) {
      await _attemptAutomatedLogin();
    }
  }

  Future<void> _attemptAutomatedLogin() async {
    print('Attempting automated login...');
    final credentials = await _authService.getCredentials(widget.bankType);
    if (credentials == null) {
      print('No credentials found for login');
      return;
    }

    final script = _authService.getLoginAutomationScript(
      widget.bankType,
      credentials['username']!,
      credentials['password']!,
    );

    try {
      print('Running login automation script...');
      await _controller.runJavaScript(script);
      print('Login automation script completed');
      setState(() {
        _isAuthenticated = true;
        _currentStep = 1; // Move to second step after login
      });
      _startAutomation();
    } catch (e) {
      print('Error during login automation: $e');
      // If automation fails, show credentials dialog again
      setState(() {
        _hasShownCredentialsDialog = false;
      });
      await _showCredentialsDialog();
    }
  }

  // Future<void> _captureAndAnalyzeScreen() async {
  //   try {
  //     // Capture the current screen using JavaScript
  //     final result = await _controller.runJavaScriptReturningResult('''
  //       (async () => {
  //         const canvas = document.createElement('canvas');
  //         const context = canvas.getContext('2d');
  //         const video = document.createElement('video');

  //         try {
  //           const stream = await navigator.mediaDevices.getDisplayMedia({
  //             preferCurrentTab: true
  //           });

  //           video.srcObject = stream;
  //           await video.play();

  //           canvas.width = video.videoWidth;
  //           canvas.height = video.videoHeight;
  //           context.drawImage(video, 0, 0);

  //           stream.getTracks().forEach(track => track.stop());

  //           return canvas.toDataURL('image/png');
  //         } catch (e) {
  //           console.error('Error capturing screen:', e);
  //           return null;
  //         }
  //       })()
  //     ''');

  //     if (result == null) {
  //       print('Failed to capture screenshot');
  //       return;
  //     }

  //     // Remove the data URL prefix
  //     final base64Image =
  //         result.toString().replaceAll('data:image/png;base64,', '');

  //     // Analyze using Replicate API
  //     final analysisResult = await _replicateService
  //         .analyzeImage('data:image/png;base64,$base64Image');

  //     print('Analysis Result: ${jsonEncode(analysisResult)}');
  //   } catch (e) {
  //     print('Error capturing/analyzing screen: $e');
  //   }
  // }

  Future<void> _capturePageHtml() async {
    try {
      final html = await _controller.runJavaScriptReturningResult('''
        document.documentElement.outerHTML;
      ''');

      print(
          'Page HTML captured (first 500 chars): ${html.toString().substring(0, 500)}...');

      // Save HTML to a file for debugging
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/page_html_${DateTime.now().millisecondsSinceEpoch}.html');
      await file.writeAsString(html.toString());
      print('HTML saved to: ${file.path}');
    } catch (e) {
      print('Error capturing page HTML: $e');
    }
  }

  Future<void> _showGuidanceOverlay(String text) async {
    setState(() {
      _showGuidance = true;
      _guidanceText = text;
    });

    // Hide guidance after 5 seconds
    _guidanceTimer?.cancel();
    _guidanceTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showGuidance = false;
        });
      }
    });
  }

  Future<void> _onPageFinished(String url) async {
    setState(() {
      _isLoading = false;
      _hasError = false;
      _errorMessage = null;
    });

    print('Page finished loading: $url');

    // Force update step based on URL and page content
    await _forceUpdateStep(url);

    // Check if we're on the login page
    if (url.contains('login') || url.contains('auth')) {
      if (!_isAuthenticated && !_hasShownCredentialsDialog) {
        _hasShownCredentialsDialog = true;
        await _showCredentialsDialog();
      } else if (_isAuthenticated) {
        // Show guidance for next steps after login
        _showGuidanceOverlay(
            'Login successful! Looking for "All Bills" button...');
      }
    }

    // If we're authenticated and on a page that might have the "All Bills" button
    if (_isAuthenticated &&
        (url.contains('dashboard') || url.contains('home'))) {
      // Show guidance for finding the All Bills button
      _showGuidanceOverlay(
          'Click on the "All Bills" button to view your subscriptions');

      // Try to click the "All Bills" button
      await _clickAllBillsButton();
    }

    // Capture and analyze screen after page loads
    // await _captureAndAnalyzeScreen();
  }

  // New method to force update step based on URL and page content
  Future<void> _forceUpdateStep(String url) async {
    print('Force updating step from URL: $url');

    // First try to detect from URL
    _updateStepFromUrl(url);

    // Then try to detect from page content with a delay to ensure page is fully loaded
    await Future.delayed(const Duration(milliseconds: 500));
    await _detectStepFromPageContent();

    // If still on step 1 and authenticated, try to detect again with a longer delay
    if (_currentStep == 1 && _isAuthenticated) {
      await Future.delayed(const Duration(seconds: 1));
      await _detectStepFromPageContent();
    }
  }

  // New method to update step based on URL
  void _updateStepFromUrl(String url) {
    print('Updating step from URL: $url');

    // Check for login page
    if (url.contains('login') || url.contains('auth')) {
      setState(() {
        _currentStep = 0; // Login step
      });
      return;
    }

    // Check for dashboard/home page
    if (url.contains('dashboard') || url.contains('home')) {
      setState(() {
        _currentStep = 1; // Navigate to All Bills step
      });
      return;
    }

    // Check for bills/subscriptions page
    if (url.contains('bills') || url.contains('subscriptions')) {
      setState(() {
        _currentStep = 2; // View subscriptions step
      });
      return;
    }

    // Check for management page
    if (url.contains('manage') || url.contains('settings')) {
      setState(() {
        _currentStep = 3; // Manage subscriptions step
      });
      return;
    }
  }

  // New method to detect step from page content
  Future<void> _detectStepFromPageContent() async {
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          // Helper function to check if text exists on page
          function hasText(text) {
            return document.body.innerText.toLowerCase().includes(text.toLowerCase());
          }
          
          // Check for login elements
          if (document.querySelector('input[type="password"]') || 
              document.querySelector('input[name="password"]') ||
              hasText('login') || hasText('sign in')) {
            return 0; // Login step
          }
          
          // Check for All Bills button or text
          if (hasText('all bills') || hasText('bills') || hasText('subscriptions')) {
            return 2; // View subscriptions step
          }
          
          // Check for management options
          if (hasText('manage') || hasText('settings') || hasText('preferences')) {
            return 3; // Manage subscriptions step
          }
          
          // Default to dashboard step
          return 1;
        })()
      ''');

      final stepIndex = int.tryParse(result.toString());
      if (stepIndex != null && stepIndex >= 0 && stepIndex < _steps.length) {
        setState(() {
          _currentStep = stepIndex;
        });
        print('Step updated to $stepIndex based on page content');
      }
    } catch (e) {
      print('Error detecting step from page content: $e');
    }
  }

  // New method to manually update step
  void _updateStep(int step) {
    if (step >= 0 && step < _steps.length) {
      setState(() {
        _currentStep = step;
      });
      _showGuidanceOverlay('Step updated to: ${_steps[step]}');
    }
  }

  Future<void> _clickAllBillsButton() async {
    print('Attempting to click "All Bills" button...');

    try {
      // First try to find the button by text content
      final textResult = await _controller.runJavaScriptReturningResult('''
        (function() {
          // Helper function to check if an element is visible
          function isVisible(element) {
            return !!(element.offsetWidth || element.offsetHeight || element.getClientRects().length);
          }
          
          // Helper function to get element text
          function getText(element) {
            return (element.textContent || element.innerText || element.value || '').toLowerCase().trim();
          }
          
          // Look for elements containing "all bills" text
          const targetText = 'all bills';
          const elements = document.querySelectorAll('*');
          
          for (const element of elements) {
            if (!isVisible(element)) continue;
            
            const text = getText(element);
            if (text.includes(targetText)) {
              console.log('Found "All Bills" element:', {
                tag: element.tagName,
                text: text,
                class: element.className,
                id: element.id
              });
              
              // Click the element
              element.click();
              return true;
            }
          }
          
          // If not found by text, try by aria-label
          const ariaElements = document.querySelectorAll('[aria-label]');
          for (const element of ariaElements) {
            if (!isVisible(element)) continue;
            
            const ariaLabel = element.getAttribute('aria-label').toLowerCase();
            if (ariaLabel.includes(targetText)) {
              console.log('Found "All Bills" element by aria-label:', {
                tag: element.tagName,
                ariaLabel: ariaLabel,
                class: element.className,
                id: element.id
              });
              
              element.click();
              return true;
            }
          }
          
          return false;
        })()
      ''');

      print('Text-based search result: $textResult');

      if (textResult.toString() == 'true') {
        _showGuidanceOverlay('Found "All Bills" button! Clicking it now...');
        return;
      }

      // If text-based approach failed, try coordinate-based approach
      print('Text-based approach failed, trying coordinate-based approach...');
      _showGuidanceOverlay('Trying to find "All Bills" button by position...');

      // Try different coordinate combinations
      final coordinateSets = [
        {'x': 200, 'y': 500},
        {'x': 300, 'y': 400},
        {'x': 250, 'y': 450},
        {'x': 150, 'y': 550},
      ];

      for (final coords in coordinateSets) {
        final result = await _controller.runJavaScriptReturningResult('''
          (function() {
            const x = ${coords['x']};
            const y = ${coords['y']};
            
            console.log('Trying to click at coordinates:', x, y);
            
            const element = document.elementFromPoint(x, y);
            if (element) {
              console.log('Found element at coordinates:', {
                tag: element.tagName,
                text: element.textContent,
                class: element.className,
                id: element.id
              });
              
              // Try to click the element
              element.click();
              return true;
            } else {
              console.log('No element found at coordinates:', x, y);
              return false;
            }
          })()
        ''');

        print('Click attempt result: $result');

        // If we successfully clicked something, wait a bit and check if we need to try again
        if (result.toString() == 'true') {
          _showGuidanceOverlay(
              'Clicked at position (${coords['x']}, ${coords['y']}). Checking if successful...');
          await Future.delayed(const Duration(seconds: 2));

          // Check if we need to try again by looking for "All Bills" text
          final checkResult = await _controller.runJavaScriptReturningResult('''
            (function() {
              const elements = document.querySelectorAll('*');
              for (const element of elements) {
                if (element.textContent && 
                    element.textContent.toLowerCase().includes('all bills')) {
                  return true;
                }
              }
              return false;
            })()
          ''');

          if (checkResult.toString() == 'true') {
            print('Successfully found "All Bills" button!');
            _showGuidanceOverlay('Successfully found "All Bills" button!');
            break;
          }
        }
      }
    } catch (e) {
      print('Error clicking "All Bills" button: $e');
      _showGuidanceOverlay(
          'Error finding "All Bills" button. Please try clicking it manually.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bankType.toUpperCase()} Bank Login'),
        actions: [
          // Add step update button
          PopupMenuButton<int>(
            icon: const Icon(Icons.menu),
            onSelected: _updateStep,
            itemBuilder: (context) => [
              for (int i = 0; i < _steps.length; i++)
                PopupMenuItem<int>(
                  value: i,
                  child: Text('Step ${i + 1}: ${_steps[i]}'),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _hasShownCredentialsDialog = false;
                _isAuthenticated = false;
                _currentStep = 0;
              });
              _automationTimer?.cancel();
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? 'An error occurred',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _isLoading = true;
                        _hasShownCredentialsDialog = false;
                      });
                      _automationTimer?.cancel();
                      _controller.reload();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          // Step indicator with manual update button
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of ${_steps.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      // Add manual step update button
                      IconButton(
                        icon: const Icon(Icons.info_outline, size: 16),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Current Step Information'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (int i = 0; i < _steps.length; i++)
                                    ListTile(
                                      title:
                                          Text('Step ${i + 1}: ${_steps[i]}'),
                                      selected: i == _currentStep,
                                      onTap: () {
                                        _updateStep(i);
                                        Navigator.pop(context);
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _steps[_currentStep],
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          // Guidance overlay
          if (_showGuidance)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _guidanceText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _showGuidance = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
