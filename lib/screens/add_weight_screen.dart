import 'package:flutter/material.dart';
import 'package:health_pet/models/pet_model.dart';

class AddWeightScreen extends StatefulWidget {
  final Pet pet;

  const AddWeightScreen({Key? key, required this.pet}) : super(key: key);

  @override
  _AddWeightScreenState createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends State<AddWeightScreen> {
  final _formKey = GlobalKey<FormState>();
  double? _weight;
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final newRecord = WeightRecord(weight: _weight!, date: _selectedDate);

      setState(() {
        widget.pet.weightHistory.add(newRecord);
      });

      Navigator.pop(context, widget.pet);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Kilo Kaydı')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Kilo (kg)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final weight = double.tryParse(value ?? '');
                  if (weight == null || weight <= 0) {
                    return 'Geçerli bir kilo girin.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _weight = double.tryParse(value ?? '');
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tarih: ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Tarih Seç'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _submit, child: const Text('Kaydet')),
            ],
          ),
        ),
      ),
    );
  }
}
