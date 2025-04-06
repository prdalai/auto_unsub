// import 'package:flutter/material.dart';
// import 'dart:convert';
// import '../../domain/services/replicate_api_service.dart';

// class ImageAnalysisScreen extends StatefulWidget {
//   const ImageAnalysisScreen({Key? key}) : super(key: key);

//   @override
//   State<ImageAnalysisScreen> createState() => _ImageAnalysisScreenState();
// }

// class _ImageAnalysisScreenState extends State<ImageAnalysisScreen> {
//   final ReplicateApiService _apiService = ReplicateApiService();
//   bool _isLoading = false;
//   String? _result;
//   String? _error;

//   Future<void> _analyzeImage(String imageUrl) async {
//     setState(() {
//       _isLoading = true;
//       _result = null;
//       _error = null;
//     });

//     try {
//       final result = await _apiService.analyzeImage(imageUrl);
//       setState(() {
//         _result = jsonEncode(result);
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Image Analysis'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             ElevatedButton(
//               onPressed: _isLoading
//                   ? null
//                   : () => _analyzeImage(
//                       'https://replicate.delivery/pbxt/MWb5phPoK0NtfxdKRdd7QkbnvAwJpWAeO7xqOZtrvY5Ned18/win11.jpeg'),
//               child: const Text('Analyze Sample Image'),
//             ),
//             const SizedBox(height: 20),
//             if (_isLoading)
//               const Center(child: CircularProgressIndicator())
//             else if (_error != null)
//               Text(
//                 'Error: $_error',
//                 style: const TextStyle(color: Colors.red),
//               )
//             else if (_result != null)
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Text(_result!),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
