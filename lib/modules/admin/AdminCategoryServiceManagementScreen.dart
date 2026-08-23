import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_booking_app/modules/admin/service_management_screen.dart';
import 'package:service_booking_app/shared/styles/colors.dart';

import '../../cubits/customer_cubit/customer_cubit.dart';
import '../../cubits/customer_cubit/sub_cubits/category_cubit/category_cubit.dart';
import '../../shared/components/classes.dart';
import '../../shared/components/components.dart';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Import animations package
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCategoryServiceManagementScreen extends StatelessWidget {
  const AdminCategoryServiceManagementScreen({Key? key}) : super(key: key);

  // Fetch all categories from Firestore
  Stream<List<Map<String, dynamic>>> _getCategories() {
    return FirebaseFirestore.instance
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Add the document ID to the data
      return data;
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    CategoryCubit getCategories = CategoryCubit.get(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        appBar: AppBar(
          title: const Text('إدارة فئات الخدمات'),
          actions: [
            CircleAvatar(
              backgroundColor: Colors.red[50],
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.red),
                onPressed: () => _showCategoryDialog(context),
              ),
            ),
            IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.red[50],
                child: Icon(Icons.search, color: Colors.red),
              ),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CategoriesSearchDelegate(
                    categories: getCategories.categories! ?? [],
                    fromAdminScreen: true,
                  ),
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return buildSpinKitFadingCircle();
            }
            if (snapshot.hasError) {
              return const Center(child: Text('حدث خطأ في تحميل الفئات'));
            }
            final categories = snapshot.data ?? [];
            if (categories.isEmpty) {
              return const Center(child: Text('لا توجد فئات بعد.'));
            }
            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(0),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ServiceManagementScreen(
                                    categoryId: category['id'],
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Category Image or Icon
                                  if (category['imageUrl'] != null)
                                    buildeCachedNetworkImage(
                                        url: category['imageUrl'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover
                                    )
                                  else
                                    CircleAvatar(
                                      backgroundColor: Colors.deepOrange[50],
                                      child: const Icon(
                                        Icons.category,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  const SizedBox(width: 16),
                                  // Category Name and Description
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Edit and Delete Buttons
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: CircleAvatar(
                                          backgroundColor: Colors.deepOrange[50],
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.deepOrange,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _showCategoryDialog(context, category: category),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            );
          },
        ),
      ),
    );
  }

  // Show a dialog to add or edit a category


  void _showCategoryDialog(BuildContext context, {Map<String, dynamic>? category}) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _nameController = TextEditingController(text: category?['name']);
    final TextEditingController _descriptionController = TextEditingController(text: category?['description']);
    File? _imageFile;
    bool isLoading = false;

    Future<void> _pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      }
    }

    Future<String?> _uploadImage() async {
      if (_imageFile == null) return null;

      final storageRef = FirebaseStorage.instance.ref().child('category_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    }

    showDialog(
      context: context,
      builder: (context) => SingleChildScrollView(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text(category == null ? 'إضافة فئة جديدة' : 'تعديل الفئة'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_imageFile != null)
                      Image.file(
                        _imageFile!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('اختر صورة'),
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الفئة',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال اسم الفئة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'وصف الفئة',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال وصف الفئة';
                        }
                        return null;
                      },
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 16),
                      buildSpinKitFadingCircle(),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() {
                        isLoading = true;
                      });
        
                      final String name = _nameController.text;
                      final String description = _descriptionController.text;
                      final String? imageUrl = await _uploadImage();
        
                      try {
                        if (category == null) {
                          await FirebaseFirestore.instance.collection('categories').add({
                            'name': name,
                            'description': description,
                            'imageUrl': imageUrl,
                            'created_at': FieldValue.serverTimestamp(),
                          });
                        } else {
                          await FirebaseFirestore.instance
                              .collection('categories')
                              .doc(category['id'])
                              .update({
                            'name': name,
                            'description': description,
                            'imageUrl': imageUrl ?? category['imageUrl'],
                          });
                        }
        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(category == null
                                  ? 'تم إضافة الفئة بنجاح'
                                  : 'تم تحديث الفئة بنجاح')),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('حدث خطأ أثناء حفظ الفئة')),
                        );
                      } finally {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // Show a confirmation dialog before deleting a category
  void _confirmDeleteCategory(BuildContext context, String categoryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذه الفئة؟'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog
              await _deleteCategory(context, categoryId); // Delete the category
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Delete a category
  Future<void> _deleteCategory(BuildContext context, String categoryId) async {
    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الفئة بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء حذف الفئة')),
      );
    }
  }
}