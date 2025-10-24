// import 'dart:io';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../ai/tflite_helper.dart';
// import '../../../ai/nutrition_database.dart';
// import '../../../controllers/data_controller.dart';
// import '../../../models/daily_log.dart';

// class CameraScanScreen extends StatefulWidget {
//   final TFLiteHelper tfliteHelper;
//   const CameraScanScreen({super.key, required this.tfliteHelper});

//   @override
//   State<CameraScanScreen> createState() => _CameraScanScreenState();
// }

// class _CameraScanScreenState extends State<CameraScanScreen> {
//   CameraController? _cameraController;
//   List<CameraDescription>? _cameras;
//   bool _isProcessing = false;
//   XFile? _capturedImage;
//   List<Detection>? _detections;
//   Size? _imageSize; // To store the original image size for scaling

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }

//   Future<void> _initializeCamera() async {
//     _cameras = await availableCameras();
//     if (_cameras != null && _cameras!.isNotEmpty) {
//       _cameraController = CameraController(
//         _cameras!.first, // Use the first available camera
//         ResolutionPreset.high,
//         enableAudio: false,
//       );
//       await _cameraController!.initialize();
//       if (mounted) {
//         setState(() {});
//       }
//     }
//   }

//   Future<void> _takePictureAndProcess() async {
//     if (_cameraController == null || !_cameraController!.value.isInitialized) {
//       return;
//     }
//     setState(() {
//       _isProcessing = true;
//     });

//     try {
//       final image = await _cameraController!.takePicture();

//       // Get image dimensions for scaling bounding boxes later
//       final decodedImage = await decodeImageFromList(await image.readAsBytes());
//       _imageSize = Size(
//         decodedImage.width.toDouble(),
//         decodedImage.height.toDouble(),
//       );

//       final detections = await widget.tfliteHelper.runInference(image.path);

//       setState(() {
//         _capturedImage = image;
//         _detections = detections;
//         _isProcessing = false;
//       });
//     } catch (e) {
//       print("Error taking picture or processing: $e");
//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }

//   void _logDetections() {
//     if (_detections == null || _detections!.isEmpty) return;

//     final dataController = Provider.of<DataController>(context, listen: false);

//     for (var detection in _detections!) {
//       final nutrientInfo = NutritionDatabase.getNutrientInfo(detection.label);
//       if (nutrientInfo != null) {
//         final newFoodItem = FoodItem(
//           id:
//               DateTime.now().millisecondsSinceEpoch.toString() +
//               detection.label,
//           name: detection.label.capitalize(), // e.g., "Idli"
//           calories: nutrientInfo.calories,
//           protein: nutrientInfo.protein,
//           carbs: nutrientInfo.carbs,
//           fat: nutrientInfo.fat,
//           mealType: 'Snacks', // Default to snacks, could be a selection
//           timestamp: DateTime.now(), // **<-- THE FIX IS HERE**
//         );
//         dataController.addFoodItem(newFoodItem);
//       }
//     }
//     // Go back to dashboard after logging
//     if (mounted) Navigator.pop(context);
//   }

//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_cameraController == null || !_cameraController!.value.isInitialized) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     if (_capturedImage != null) {
//       return _buildResultsView();
//     }

//     return _buildCameraView();
//   }

//   Widget _buildCameraView() {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           Center(child: CameraPreview(_cameraController!)),
//           Positioned(
//             bottom: 40,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: GestureDetector(
//                 onTap: _isProcessing ? null : _takePictureAndProcess,
//                 child: Container(
//                   width: 70,
//                   height: 70,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.transparent,
//                     border: Border.all(color: Colors.white, width: 4),
//                   ),
//                   child: Center(
//                     child: _isProcessing
//                         ? const CircularProgressIndicator(color: Colors.white)
//                         : Container(
//                             width: 58,
//                             height: 58,
//                             decoration: const BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: Colors.white,
//                             ),
//                           ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             top: 50,
//             left: 20,
//             child: CircleAvatar(
//               backgroundColor: Colors.black.withOpacity(0.5),
//               child: IconButton(
//                 icon: const Icon(
//                   Icons.arrow_back,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildResultsView() {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Detection Results"),
//         leading: IconButton(
//           icon: const Icon(Icons.close),
//           onPressed: () => setState(() {
//             _capturedImage = null;
//             _detections = null;
//             _imageSize = null;
//           }),
//         ),
//       ),
//       body: (_detections == null || _imageSize == null)
//           ? const Center(child: Text("No detections found."))
//           : Stack(
//               fit: StackFit.expand,
//               children: [
//                 Image.file(File(_capturedImage!.path), fit: BoxFit.contain),
//                 // Draw bounding boxes, scaled to the view
//                 if (_detections != null)
//                   LayoutBuilder(
//                     builder: (context, constraints) {
//                       return CustomPaint(
//                         painter: BoundingBoxPainter(
//                           detections: _detections!,
//                           originalImageSize: _imageSize!,
//                           screenSize: constraints.biggest,
//                         ),
//                       );
//                     },
//                   ),
//               ],
//             ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: (_detections?.isEmpty ?? true) ? null : _logDetections,
//         label: const Text('Add to Log'),
//         icon: const Icon(Icons.check),
//         backgroundColor: (_detections?.isEmpty ?? true)
//             ? Colors.grey
//             : Theme.of(context).colorScheme.secondary,
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//     );
//   }
// }

// // Custom Painter to draw the bounding boxes on the image
// class BoundingBoxPainter extends CustomPainter {
//   final List<Detection> detections;
//   final Size originalImageSize;
//   final Size screenSize;

//   BoundingBoxPainter({
//     required this.detections,
//     required this.originalImageSize,
//     required this.screenSize,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.redAccent
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3.0;

//     // Calculate scaling factors
//     final double scaleX = screenSize.width / originalImageSize.width;
//     final double scaleY = screenSize.height / originalImageSize.height;

//     // Use the smaller scale factor to maintain aspect ratio (fitInside)
//     final double scale = scaleX < scaleY ? scaleX : scaleY;

//     // Calculate offsets to center the image
//     final double offsetX =
//         (screenSize.width - originalImageSize.width * scale) / 2;
//     final double offsetY =
//         (screenSize.height - originalImageSize.height * scale) / 2;

//     for (var detection in detections) {
//       // Scale the bounding box coordinates
//       final scaledRect = Rect.fromLTWH(
//         detection.boundingBox.left * scale + offsetX,
//         detection.boundingBox.top * scale + offsetY,
//         detection.boundingBox.width * scale,
//         detection.boundingBox.height * scale,
//       );

//       // Draw the rectangle
//       canvas.drawRect(scaledRect, paint);

//       // Draw the label background and text
//       final textPainter = TextPainter(
//         text: TextSpan(
//           text:
//               ' ${detection.label} (${(detection.confidence * 100).toStringAsFixed(0)}%) ',
//           style: const TextStyle(
//             color: Colors.white,
//             backgroundColor: Colors.redAccent,
//             fontSize: 16.0,
//           ),
//         ),
//         textDirection: TextDirection.ltr,
//       );
//       textPainter.layout();
//       textPainter.paint(
//         canvas,
//         Offset(scaledRect.left, scaledRect.top - textPainter.height),
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }

// // Helper to capitalize strings
// extension StringExtension on String {
//   String capitalize() {
//     if (isEmpty) return "";
//     return "${this[0].toUpperCase()}${substring(1)}";
//   }
// }

import 'dart:io';
import 'dart:math'; // Import for Random
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui; // Needed for decodeImageFromList

import '../../../ai/tflite_helper.dart';
import '../../../ai/nutrition_database.dart';
import '../../../controllers/data_controller.dart';
import '../../../models/daily_log.dart';

class CameraScanScreen extends StatefulWidget {
  final TFLiteHelper tfliteHelper;
  const CameraScanScreen({super.key, required this.tfliteHelper});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  XFile? _capturedImage;
  List<Detection>? _detections;
  Size? _imageSize; // To store the original image size for scaling

  @override
  void initState() {
    super.initState();
    print("CameraScanScreen: initState"); // Debug
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    print("CameraScanScreen: Initializing camera..."); // Debug
    // Ensure model is loaded before initializing camera
    if (!widget.tfliteHelper.isModelLoaded) {
      print("CameraScanScreen: Waiting for model to load...");
      await widget.tfliteHelper.loadModel();
      if (!widget.tfliteHelper.isModelLoaded && mounted) {
        // Check mounted before showing SnackBar/popping
        print(
          "CameraScanScreen: Model failed to load, cannot initialize camera.",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: AI Model failed to load.")),
        );
        Navigator.pop(context);
        return;
      }
      print("CameraScanScreen: Model loaded successfully.");
    }

    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        print(
          "CameraScanScreen: Found ${_cameras!.length} cameras. Using first one.",
        ); // Debug
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: Platform.isIOS
              ? ImageFormatGroup.bgra8888
              : ImageFormatGroup.yuv420, // Set format group
        );

        print("CameraScanScreen: Initializing CameraController..."); // Debug
        await _cameraController!.initialize();
        print("CameraScanScreen: CameraController initialized."); // Debug

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            print(
              "CameraScanScreen: Camera initialized, updating state.",
            ); // Debug
          });
        }
      } else {
        print("CameraScanScreen: No cameras found on device."); // Debug
        if (mounted) {
          // Show error if no cameras found
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error: No cameras found on this device."),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print("--- CameraScanScreen: Error initializing camera: $e ---"); // Debug
      if (mounted) {
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error initializing camera: ${e.toString()}")),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _takePictureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print("CameraScanScreen: Camera not ready."); // Debug
      return;
    }
    if (_isProcessing) {
      print("CameraScanScreen: Already processing, ignoring tap."); // Debug
      return;
    }

    setState(() {
      _isProcessing = true;
      print("CameraScanScreen: Taking picture...");
    }); // Debug

    XFile? image; // Declare image variable outside try block

    try {
      image = await _cameraController!.takePicture();
      print("CameraScanScreen: Picture taken: ${image.path}"); // Debug

      print("CameraScanScreen: Reading image bytes for size..."); // Debug
      final imageBytes = await image.readAsBytes();
      print("CameraScanScreen: Decoding image..."); // Debug
      // Use decodeImageFromList for broader compatibility
      final decodedImage = await decodeImageFromList(imageBytes);
      if (decodedImage == null) {
        throw Exception("Failed to decode image");
      }
      _imageSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );
      print("CameraScanScreen: Image size: $_imageSize"); // Debug

      print("CameraScanScreen: Running inference..."); // Debug
      final detections = await widget.tfliteHelper.runInference(image.path);
      print(
        "CameraScanScreen: Inference complete. Found ${detections.length} detections.",
      ); // Debug

      if (mounted) {
        setState(() {
          _capturedImage = image;
          _detections = detections;
          _isProcessing = false;
        });
      }
    } catch (e, stacktrace) {
      print(
        "--- CameraScanScreen: Error taking picture or processing: $e ---",
      ); // Debug
      print("Stacktrace: $stacktrace"); // Debug more details
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _capturedImage = null; // Reset image on error
          _detections = null;
          _imageSize = null;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error processing image: ${e.toString()}")),
          );
        });
      }
      // Clean up temp file if picture was taken but processing failed
      if (image != null) {
        try {
          await File(image.path).delete();
        } catch (_) {}
      }
    }
  }

  void _logDetections() {
    print("CameraScanScreen: Logging detections..."); // Debug
    if (_detections == null || _detections!.isEmpty) {
      print("CameraScanScreen: No detections to log."); // Debug
      return;
    }

    final dataController = Provider.of<DataController>(context, listen: false);

    int loggedCount = 0;
    for (var detection in _detections!) {
      final nutrientInfo = NutritionDatabase.getNutrientInfo(detection.label);
      print(
        "CameraScanScreen: Checking nutrition for '${detection.label}'...",
      ); // Debug
      if (nutrientInfo != null) {
        final newFoodItem = FoodItem(
          id:
              DateTime.now().millisecondsSinceEpoch.toString() +
              detection.label +
              Random().nextInt(1000).toString(), // More unique ID
          name: detection.label.capitalize(), // e.g., "Idli"
          calories: nutrientInfo.calories,
          protein: nutrientInfo.protein,
          carbs: nutrientInfo.carbs,
          fat: nutrientInfo.fat,
          mealType:
              'Snacks', // TODO: Allow user to select meal type on this screen
          timestamp: DateTime.now(), // ** THIS WAS THE FIX **
        );
        print(
          "CameraScanScreen: Adding item to log: ${newFoodItem.name}",
        ); // Debug
        dataController.addFoodItem(newFoodItem);
        loggedCount++;
      } else {
        print(
          "CameraScanScreen: No nutrition info found for '${detection.label}'. Skipping.",
        ); // Debug
      }
    }
    print("CameraScanScreen: Logged $loggedCount items."); // Debug
    if (mounted) Navigator.pop(context); // Go back to dashboard
  }

  void _retakePicture() {
    print("CameraScanScreen: Retaking picture."); // Debug
    // Clean up the previously captured image file
    if (_capturedImage != null) {
      try {
        File(_capturedImage!.path).delete();
      } catch (_) {}
    }
    setState(() {
      _capturedImage = null;
      _detections = null;
      _imageSize = null;
    });
  }

  @override
  void dispose() {
    print("CameraScanScreen: dispose"); // Debug
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(
      "CameraScanScreen: build (Camera Initialized: $_isCameraInitialized)",
    ); // Debug
    if (!_isCameraInitialized) {
      return Scaffold(
        // Provide Scaffold even during init
        appBar: AppBar(title: const Text("Initializing Camera...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_capturedImage != null) {
      print("CameraScanScreen: Showing results view."); // Debug
      return _buildResultsView();
    }
    print("CameraScanScreen: Showing camera view."); // Debug
    return _buildCameraView();
  }

  // --- UI Builder Methods ---

  Widget _buildCameraView() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: Text("Camera Failed to Initialize")),
      );
    }
    final mediaSize = MediaQuery.of(context).size;
    final cameraAspectRatio = _cameraController!.value.aspectRatio;

    // Calculate scale factor needed for the CameraPreview to cover the screen
    // Compare aspect ratios to determine how to scale
    var scale = mediaSize.aspectRatio * cameraAspectRatio;
    // Adjust scale if clipping is needed horizontally or vertically
    if (scale < 1) scale = 1 / scale;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center, // Center the scaled preview
        children: [
          // --- FIX FOR SCALING/ROTATION ---
          // Apply scaling transform to make the preview cover the screen
          Transform.scale(
            scale: scale,
            child: CameraPreview(_cameraController!),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isProcessing ? null : _takePictureAndProcess,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top:
                MediaQuery.of(context).padding.top +
                10, // Adjust for status bar
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detection Results"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: "Retake Picture",
          onPressed: _retakePicture,
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(_capturedImage!.path), fit: BoxFit.contain),
          if (_detections != null &&
              _imageSize != null &&
              _detections!.isNotEmpty) // Check if detections exist
            LayoutBuilder(
              builder: (context, constraints) {
                final Size displaySize = constraints.biggest;
                final fittedSizes = applyBoxFit(
                  BoxFit.contain,
                  _imageSize!,
                  displaySize,
                );
                final Size sourceSize = fittedSizes.source;
                final Size destinationSize = fittedSizes.destination;
                final double scale = min(
                  destinationSize.width / sourceSize.width,
                  destinationSize.height / sourceSize.height,
                );
                final double offsetX =
                    (displaySize.width - sourceSize.width * scale) / 2;
                final double offsetY =
                    (displaySize.height - sourceSize.height * scale) / 2;

                return CustomPaint(
                  painter: BoundingBoxPainter(
                    detections: _detections!,
                    originalImageSize: _imageSize!,
                    scale: scale,
                    offsetX: offsetX,
                    offsetY: offsetY,
                  ),
                );
              },
            )
          // Show "No detections found" only if processing finished and detections are empty
          else if (!_isProcessing && (_detections?.isEmpty ?? true))
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                color: Colors.black.withOpacity(0.6),
                child: const Text(
                  "No food items detected.",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_detections?.isEmpty ?? true) ? null : _logDetections,
        label: const Text('Add to Log'),
        icon: const Icon(Icons.check),
        backgroundColor: (_detections?.isEmpty ?? true)
            ? Colors.grey
            : Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.black,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Custom Painter (remains the same)
class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final Size originalImageSize;
  final double scale;
  final double offsetX;
  final double offsetY;

  BoundingBoxPainter({
    required this.detections,
    required this.originalImageSize,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textStyle = const TextStyle(
      color: Colors.white,
      backgroundColor: Colors.redAccent,
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
    );

    for (var detection in detections) {
      // Scale the bounding box coordinates
      final scaledRect = Rect.fromLTWH(
        detection.boundingBox.left * scale + offsetX,
        detection.boundingBox.top * scale + offsetY,
        detection.boundingBox.width * scale,
        detection.boundingBox.height * scale,
      );

      // Draw the rectangle
      canvas.drawRect(scaledRect, paint);

      // Prepare label text
      final textSpan = TextSpan(
        text:
            ' ${detection.label.capitalize()} (${(detection.confidence * 100).toStringAsFixed(0)}%) ', // Add padding
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();

      // Calculate position for the label (above the box)
      double textX = scaledRect.left;
      double textY =
          scaledRect.top -
          textPainter.height -
          2; // Position above with padding

      // Ensure label doesn't go off-screen top
      if (textY < 0) {
        textY = scaledRect.bottom + 2; // Move below if no space above
      }
      // Ensure label doesn't go off-screen left/right (simple check)
      if (textX < 0) textX = 0;
      if (textX + textPainter.width > size.width) {
        textX = size.width - textPainter.width;
      }

      // Draw the label text (no separate background needed as it's in TextStyle)
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true; // Repaint whenever detections change
}

// Helper needed also in TFLiteHelper (move to utils?)
// extension StringExtension on String {
//   String capitalize() {
//     if (isEmpty) return "";
//     return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
//   }
// }
