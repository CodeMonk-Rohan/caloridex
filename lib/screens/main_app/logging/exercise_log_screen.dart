import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../controllers/data_controller.dart';
import '../../../models/daily_log.dart';

class ExerciseLogScreen extends StatefulWidget {
  const ExerciseLogScreen({super.key});

  @override
  State<ExerciseLogScreen> createState() => _ExerciseLogScreenState();
}

class _ExerciseLogScreenState extends State<ExerciseLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseNameController = TextEditingController();
  final _caloriesBurnedController = TextEditingController();

  void _saveExerciseItem() {
    if (_formKey.currentState!.validate()) {
      final exerciseItem = ExerciseItem(
        id: const Uuid().v4(), // Generate a unique ID
        name: _exerciseNameController.text,
        caloriesBurned: int.parse(_caloriesBurnedController.text),
        timestamp: DateTime.now(),
      );

      // Use the DataController to save the item
      Provider.of<DataController>(
        context,
        listen: false,
      ).addExerciseItem(exerciseItem);

      // Go back to the dashboard
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Exercise')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _exerciseNameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name (e.g., Running, Gym)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Exercise name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caloriesBurnedController,
                decoration: const InputDecoration(labelText: 'Calories Burned'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Calories burned is required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveExerciseItem,
                child: const Text('Add Exercise'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
