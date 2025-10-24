import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../controllers/data_controller.dart';
import '../../../models/daily_log.dart';

class ManualFoodLogScreen extends StatefulWidget {
  const ManualFoodLogScreen({super.key});

  @override
  State<ManualFoodLogScreen> createState() => _ManualFoodLogScreenState();
}

class _ManualFoodLogScreenState extends State<ManualFoodLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  String _selectedMealType = 'Breakfast'; // Default value

  void _saveFoodItem() {
    if (_formKey.currentState!.validate()) {
      final foodItem = FoodItem(
        id: const Uuid().v4(), // Generate a unique ID
        name: _foodNameController.text,
        calories: int.parse(_caloriesController.text),
        protein: double.tryParse(_proteinController.text) ?? 0.0,
        carbs: double.tryParse(_carbsController.text) ?? 0.0,
        fat: double.tryParse(_fatController.text) ?? 0.0,
        mealType: _selectedMealType,
        timestamp: DateTime.now(),
      );

      // Use the DataController to save the item
      Provider.of<DataController>(context, listen: false).addFoodItem(foodItem);

      // Go back to the dashboard
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Food Manually')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(_foodNameController, 'Food Name'),
              const SizedBox(height: 16),
              _buildTextField(_caloriesController, 'Calories', isNumber: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _proteinController,
                      'Protein (g)',
                      isNumber: true,
                      isRequired: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      _carbsController,
                      'Carbs (g)',
                      isNumber: true,
                      isRequired: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      _fatController,
                      'Fat (g)',
                      isNumber: true,
                      isRequired: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildMealTypeDropdown(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveFoodItem,
                child: const Text('Add Food'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '$label is required';
        }
        if (isNumber &&
            value != null &&
            value.isNotEmpty &&
            double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildMealTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedMealType,
      decoration: const InputDecoration(labelText: 'Meal Type'),
      items: ['Breakfast', 'Lunch', 'Dinner', 'Snacks']
          .map((label) => DropdownMenuItem(value: label, child: Text(label)))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedMealType = value;
          });
        }
      },
    );
  }
}
