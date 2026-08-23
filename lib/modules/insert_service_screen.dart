import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InsertServiceScreen extends StatelessWidget {
  const InsertServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insert Service'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a New Service',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Service Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Service Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final description = descriptionController.text.trim();
                  final price = double.tryParse(priceController.text.trim());

                  if (name.isEmpty) {
                    _showToast(context, 'Please enter the service name.');
                    return;
                  }

                  if (description.isEmpty) {
                    _showToast(context, 'Please enter the service description.');
                    return;
                  }

                  if (price == null || price <= 0) {
                    _showToast(context, 'Please enter a valid price.');
                    return;
                  }

                  // Save service to Firestore with an auto-generated ID
                  try {
                    await FirebaseFirestore.instance.collection('services').add({
                      'name': name,
                      'description': description,
                      'price': price,
                    });

                    _showToast(context, 'Service added successfully!');
                    Navigator.pop(context);
                  } catch (e) {
                    _showToast(context, 'Failed to add service: $e');
                  }
                },
                child: const Text('Add Service'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
