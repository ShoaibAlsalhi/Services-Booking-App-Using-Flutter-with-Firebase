import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_booking_app/shared/components/components.dart';
import '../../../models/advertisement_model/advertisement_model.dart';
import 'add_advertisement_screen.dart';


import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_booking_app/shared/components/components.dart';
import 'package:service_booking_app/shared/styles/colors.dart';
import '../../../models/advertisement_model/advertisement_model.dart';
import 'add_advertisement_screen.dart';

class AdvertisementsListScreen extends StatefulWidget {
  const AdvertisementsListScreen({super.key});

  @override
  State<AdvertisementsListScreen> createState() => _AdvertisementsListScreenState();
}

class _AdvertisementsListScreenState extends State<AdvertisementsListScreen> {
  late Future<List<AdvertisementModel>> _adsFuture;

  @override
  void initState() {
    super.initState();
    _adsFuture = AdvertisementRepository().fetchAdvertisements();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // RTL for Arabic
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        appBar: AppBar(
          title: const Text('الإعلانات'),
          actions: [
            CircleAvatar(
              backgroundColor: Colors.red[50],
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.red),
                onPressed: () => navigateTo(context, AdminAddAdvertisementScreen()),
              ),
            ),
          ],
        ),
        body: FutureBuilder<List<AdvertisementModel>>(
          future: _adsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return buildSpinKitFadingCircle(); // Consistent loader
            } else if (snapshot.hasError) {
              return Center(child: Text('خطأ: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('لا توجد إعلانات حالياً.'));
            }

            final ads = snapshot.data!;
            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: ads.length,
                itemBuilder: (context, index) {
                  final ad = ads[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      verticalOffset: 50.0, // Slide animation
                      child: FadeInAnimation(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              textDirection: TextDirection.rtl, // RTL alignment
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Ad Image (or placeholder)
                                ad.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: buildeCachedNetworkImage(
                                    url: ad.imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                    : const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                                const SizedBox(width: 10),
                                // Ad Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ad.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ad.description,
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Edit Button
                                IconButton(
                                  icon: CircleAvatar(
                                    backgroundColor: Colors.deepOrange[50],
                                    child: const Icon(Icons.edit, color: Colors.deepOrange),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditAdvertisementScreen(ad: ad),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}


////////////////////////////////



class EditAdvertisementScreen extends StatefulWidget {
  final AdvertisementModel ad;

  const EditAdvertisementScreen({super.key, required this.ad});

  @override
  State<EditAdvertisementScreen> createState() => _EditAdvertisementScreenState();
}

class _EditAdvertisementScreenState extends State<EditAdvertisementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  File? _pickedImageFile;
  final _picker = ImagePicker();
  late String _imageUrl;

  @override
  void initState() {
    _titleController = TextEditingController(text: widget.ad.title);
    _descriptionController = TextEditingController(text: widget.ad.description);
    _imageUrl = widget.ad.imageUrl;
    super.initState();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImageFile = File(picked.path);
      });
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    final fileName = 'ads/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      String imageUrl = _imageUrl;

      if (_pickedImageFile != null) {
        imageUrl = await _uploadImage(_pickedImageFile!);
      }

      await FirebaseFirestore.instance
          .collection('advertisements')
          .doc(widget.ad.id)
          .update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الإعلان بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الإعلان')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _pickedImageFile != null
                    ? Image.file(_pickedImageFile!, height: 180, fit: BoxFit.cover)
                    : _imageUrl.isNotEmpty
                    ? Image.network(_imageUrl, height: 180, fit: BoxFit.cover)
                    : Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Center(child: Text('اختر صورة')),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'العنوان'),
                validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال العنوان' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف'),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال الوصف' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('حفظ التعديلات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
