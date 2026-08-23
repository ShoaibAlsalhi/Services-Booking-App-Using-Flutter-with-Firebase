import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/advertisement_model/advertisement_model.dart';

class AdminAddAdvertisementScreen extends StatefulWidget {
  const AdminAddAdvertisementScreen({Key? key}) : super(key: key);

  @override
  State<AdminAddAdvertisementScreen> createState() => _AdminAddAdvertisementScreenState();
}

class _AdminAddAdvertisementScreenState extends State<AdminAddAdvertisementScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _imageFile;

  bool isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final fileName = 'ads/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitAdvertisement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
    }

    await FirebaseFirestore.instance.collection('advertisements').add({
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'imageUrl': imageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      isLoading = false;
      titleController.clear();
      descriptionController.clear();
      _imageFile = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إضافة الإعلان بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة إعلان جديد'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'عنوان الإعلان'),
                    validator: (value) => value!.isEmpty ? 'الرجاء إدخال العنوان' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'وصف الإعلان'),
                    validator: (value) => value!.isEmpty ? 'الرجاء إدخال الوصف' : null,
                  ),
                  const SizedBox(height: 16),
                  if (_imageFile != null)
                    Image.file(_imageFile!, height: 150),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('اختيار صورة'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submitAdvertisement,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('نشر الإعلان'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}















