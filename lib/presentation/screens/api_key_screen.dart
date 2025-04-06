// import 'package:flutter/material.dart';
// import '../../config/api_config.dart';

// class ApiKeyScreen extends StatefulWidget {
//   const ApiKeyScreen({Key? key}) : super(key: key);

//   @override
//   State<ApiKeyScreen> createState() => _ApiKeyScreenState();
// }

// class _ApiKeyScreenState extends State<ApiKeyScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _apiKeyController = TextEditingController();
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadApiKey();
//   }

//   @override
//   void dispose() {
//     _apiKeyController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadApiKey() async {
//     setState(() => _isLoading = true);
//     try {
//       final apiKey = await ApiConfig.getReplicateApiKey();
//       _apiKeyController.text = apiKey;
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading API key: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _saveApiKey() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);
//     try {
//       await ApiConfig.setReplicateApiKey(_apiKeyController.text);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('API key saved successfully')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving API key: $e')),
//         );
//       }
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Replicate API Key'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               TextFormField(
//                 controller: _apiKeyController,
//                 decoration: const InputDecoration(
//                   labelText: 'API Key',
//                   hintText: 'Enter your Replicate API key',
//                 ),
//                 obscureText: true,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your API key';
//                   }
//                   if (!value.startsWith('r8_')) {
//                     return 'Invalid API key format';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               if (_isLoading)
//                 const Center(child: CircularProgressIndicator())
//               else
//                 ElevatedButton(
//                   onPressed: _saveApiKey,
//                   child: const Text('Save API Key'),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
