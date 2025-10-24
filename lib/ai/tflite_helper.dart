import 'dart:io'; // Import dart:io for File
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:math';
import 'package:flutter/material.dart'; // Import for Rect

// Represents a single detection from the model
class Detection {
  final Rect boundingBox; // Location of the detected object
  final String label; // Class name (e.g., "Idli")
  final double confidence; // Confidence score (0.0 to 1.0)

  Detection(this.boundingBox, this.label, this.confidence);

  @override
  String toString() {
    // Helpful for debugging
    return 'Detection(label: $label, confidence: ${confidence.toStringAsFixed(2)}, box: ${boundingBox.toString()})';
  }
}

class TFLiteHelper {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isModelLoaded = false;

  // Input details (adjust if your model differs)
  static const int inputSize = 640;
  // --- TEMPORARILY LOWER CONFIDENCE FOR DEBUGGING ---
  static const double confidenceThreshold =
      0.1; // Lowered from 0.45, adjust as needed

  bool get isModelLoaded => _isModelLoaded; // Getter to check status

  Future<void> loadModel() async {
    if (_isModelLoaded) {
      print("TFLiteHelper: Model already loaded.");
      return;
    }

    print(
      "TFLiteHelper: Attempting to load TFLite model and labels...",
    ); // Debug start

    try {
      // Load the TFLite model from assets
      _interpreter = await Interpreter.fromAsset('assets/best_float32.tflite');
      print('TFLiteHelper: Interpreter instance created.');

      // Load labels from assets
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList();
      print(
        'TFLiteHelper: Labels raw data loaded. Found ${_labels?.length ?? 0} labels.',
      );

      if (_labels == null || _labels!.isEmpty) {
        print(
          'TFLiteHelper Error: Labels file is empty or could not be processed.',
        );
        _isModelLoaded = false;
        _interpreter?.close(); // Clean up interpreter if labels failed
        return;
      }
      if (_interpreter == null) {
        print(
          'TFLiteHelper Error: Interpreter is null after attempting to load.',
        );
        _isModelLoaded = false;
        return;
      }

      // Explicitly allocate tensors
      try {
        _interpreter!.allocateTensors();
        print("TFLiteHelper: Tensors allocated.");
      } catch (e) {
        print("TFLiteHelper Error allocating tensors: $e");
        _isModelLoaded = false;
        _interpreter?.close();
        return;
      }

      _isModelLoaded = true;
      print(
        "TFLiteHelper: Model and labels loaded successfully. Labels: $_labels",
      ); // Confirm success
    } catch (e) {
      print('--- TFLiteHelper FATAL ERROR loading model or labels: $e ---');
      _isModelLoaded = false;
      _interpreter?.close(); // Ensure interpreter is closed on error
    }
  }

  Future<List<Detection>> runInference(String imagePath) async {
    if (!_isModelLoaded || _interpreter == null || _labels == null) {
      print("TFLiteHelper Error: Model not loaded, cannot run inference.");
      // Consider attempting loadModel() again here if needed
      return []; // Return empty if not loaded
    }

    print(
      "TFLiteHelper: Starting inference for image: $imagePath",
    ); // Debug start inference

    try {
      // 1. Read and Decode Image
      print("TFLiteHelper: Reading image bytes...");
      final imageBytes = await File(imagePath).readAsBytes();
      print("TFLiteHelper: Decoding image...");
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        print("TFLiteHelper Error: Decoding image failed.");
        return [];
      }
      final imageWidth = originalImage.width;
      final imageHeight = originalImage.height;
      print("TFLiteHelper: Original image size: ${imageWidth}x$imageHeight");

      // 2. Preprocess Image: Resize and Normalize
      print("TFLiteHelper: Resizing image to ${inputSize}x$inputSize...");
      img.Image resizedImage = img.copyResize(
        originalImage,
        width: inputSize,
        height: inputSize,
      );

      print(
        "TFLiteHelper: Converting image to input tensor bytes (Float32List)...",
      );
      // Convert image to Float32List buffer, assuming normalization to [0, 1]
      var inputTensorBuffer = Float32List(1 * inputSize * inputSize * 3);
      int pixelIndex = 0;
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          img.Pixel pixel = resizedImage.getPixel(x, y);
          inputTensorBuffer[pixelIndex++] = pixel.r / 255.0; // Normalize R
          inputTensorBuffer[pixelIndex++] = pixel.g / 255.0; // Normalize G
          inputTensorBuffer[pixelIndex++] = pixel.b / 255.0; // Normalize B
        }
      }
      // Reshape to the expected input shape [1, height, width, channels]
      final inputTensor = inputTensorBuffer.reshape([
        1,
        inputSize,
        inputSize,
        3,
      ]);
      print(
        "TFLiteHelper: Input tensor prepared with shape: ${inputTensor.shape}",
      );

      // 3. Prepare Output Tensor(s)
      // Your model's output shape is (1, 300, 6)
      // [batch, num_detections, box_coords(x,y,w,h) + score + class_id]
      const int numDetections = 300;
      const int numOutputValues = 6;
      var outputTensor = List.filled(
        1 * numDetections * numOutputValues,
        0.0,
      ).reshape([1, numDetections, numOutputValues]);
      print(
        "TFLiteHelper: Output tensor prepared with shape: ${outputTensor.shape}",
      );

      // 4. Run Inference
      print("TFLiteHelper: Running interpreter...");
      final Map<int, Object> outputs = {}; // Use Map for outputs
      outputs[0] = outputTensor; // Assign buffer to output index 0

      // Run inference using runForMultipleInputs even if only one input/output
      _interpreter!.runForMultipleInputs([inputTensor], outputs);
      print("TFLiteHelper: Interpreter run complete.");

      // 5. Postprocess Output
      print("TFLiteHelper: Postprocessing detections...");
      List<Detection> detections = [];

      // Get the output tensor data (might be dynamic)
      var outputData = outputs[0];

      // Check if the output structure is as expected
      if (outputData is List &&
          outputData.isNotEmpty &&
          outputData[0] is List &&
          (outputData[0] as List).isNotEmpty &&
          (outputData[0] as List)[0] is List) {
        // Cast to the expected structure, but keep inner numbers as dynamic for now
        var results = outputData as List<List<List<dynamic>>>;

        print("TFLiteHelper Raw Output Sample (first 5 detections):"); // Debug
        for (int i = 0; i < min(5, results[0].length); ++i) {
          print(results[0][i]);
        }

        for (int i = 0; i < numDetections; i++) {
          // Access detection data - elements might be int or double
          var detectionData = results[0][i];

          // Safely convert confidence to double
          double confidence = (detectionData[4] as num).toDouble();

          if (confidence > confidenceThreshold) {
            // Safely convert class ID to double then int
            double classIdDouble = (detectionData[5] as num).toDouble();
            int classId = classIdDouble.toInt();

            if (classId >= 0 && classId < _labels!.length) {
              String label = _labels![classId];

              // Safely convert box coordinates to double
              double centerX =
                  (detectionData[0] as num).toDouble() * imageWidth;
              double centerY =
                  (detectionData[1] as num).toDouble() * imageHeight;
              double w = (detectionData[2] as num).toDouble() * imageWidth;
              double h = (detectionData[3] as num).toDouble() * imageHeight;

              double left = centerX - (w / 2);
              double top = centerY - (h / 2);

              // Clamp coordinates to image bounds
              left = left.clamp(0.0, imageWidth.toDouble());
              top = top.clamp(0.0, imageHeight.toDouble());
              double right = (left + w).clamp(0.0, imageWidth.toDouble());
              double bottom = (top + h).clamp(0.0, imageHeight.toDouble());

              Rect boundingBox = Rect.fromLTRB(left, top, right, bottom);

              detections.add(Detection(boundingBox, label, confidence));
              print(
                "TFLiteHelper Found: $label (${confidence.toStringAsFixed(2)}) at $boundingBox",
              );
            } else {
              print(
                "TFLiteHelper Warning: Detected class ID $classId is out of bounds (Labels: ${_labels!.length}). Confidence: ${confidence.toStringAsFixed(2)}",
              );
            }
          }
        }
      } else {
        print("TFLiteHelper Error: Unexpected output tensor structure.");
        print("Received output type: ${outputData.runtimeType}");
        // Optionally print more details about outputData if needed
      }

      print(
        "TFLiteHelper: Postprocessing complete. Found ${detections.length} detections above threshold ${confidenceThreshold}.",
      );
      return detections;
    } catch (e, stacktrace) {
      print('--- TFLiteHelper ERROR during inference: $e ---');
      print('Stacktrace: $stacktrace'); // Print stacktrace for more details
      return []; // Return empty list on error
    }
  }

  void dispose() {
    print("TFLiteHelper: Disposing TFLite interpreter.");
    _interpreter?.close();
    _isModelLoaded = false;
  }
}

// Helper needed in camera_scan_screen.dart to provide context for asset loading
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Helper moved here or put in a common utils file
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}"; // Ensure rest is lowercase
  }
}
