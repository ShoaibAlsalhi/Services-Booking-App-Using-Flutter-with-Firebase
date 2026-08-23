import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_booking_app/shared/styles/colors.dart';

import '../../../models/payment_method_model/payment_method_model.dart';
import '../../../shared/components/components.dart';


import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'add_payment_method_screen.dart'; // Import animations package

class PaymentMethodsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        appBar: AppBar(
          title: Text('طرق الدفع'),
          actions: [
            CircleAvatar(
              backgroundColor: Colors.red[50],
              child: IconButton(
                icon: const Icon(Icons.add,color: Colors.red,),
                onPressed: () => navigateTo(context, AddPaymentMethodScreen()),
              ),
            ),
          ],
        ),
        body: FutureBuilder<List<PaymentMethod>>(
          future: PaymentMethod.fetchPaymentMethods(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return buildSpinKitFadingCircle();
            } else if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('لا توجد طرق دفع متاحة.'));
            } else {
              List<PaymentMethod> paymentMethods = snapshot.data!;
              return AnimationLimiter(
                child: ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: paymentMethods.length,
                  itemBuilder: (context, index) {
                    PaymentMethod method = paymentMethods[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        verticalOffset: 50.0, // Slide from the bottom
                        child: FadeInAnimation(
                          child: Container(
                            margin: EdgeInsets.only(bottom: 8),
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
                                textDirection: TextDirection.rtl, // Ensures RTL layout
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Payment Image or Default Icon
                                  method.imageUrl.isNotEmpty
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: buildeCachedNetworkImage(
                                      url: method.imageUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                      : const Icon(Icons.payment, size: 50, color: Colors.grey),

                                  const SizedBox(width: 10), // Space between image and text

                                  // Payment Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          method.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'رقم الحساب: ${method.accountNumber}',
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                                          builder: (context) => EditPaymentMethodScreen(
                                            paymentMethod: method,
                                          ),
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
            }
          },
        ),
      ),
    );
  }
}


//////////////////////////////////






class EditPaymentMethodScreen extends StatefulWidget {
  final PaymentMethod paymentMethod;

  EditPaymentMethodScreen({required this.paymentMethod});

  @override
  _EditPaymentMethodScreenState createState() => _EditPaymentMethodScreenState();
}

class _EditPaymentMethodScreenState extends State<EditPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _accountNumberController;
  File? _imageFile; // To store the selected image file
  final ImagePicker _picker = ImagePicker(); // For picking images
  bool _isLoading = false; // To track loading state

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.paymentMethod.name);
    _accountNumberController = TextEditingController(text: widget.paymentMethod.accountNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Function to upload the image to Firebase Storage and return the download URL
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('payment_method_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحميل الصورة: $e')),
      );
      return null;
    }
  }

  Future<void> _updatePaymentMethod() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loader
      });

      try {
        String? imageUrl = widget.paymentMethod.imageUrl;

        // If a new image is selected, upload it and get the new URL
        if (_imageFile != null) {
          imageUrl = await _uploadImage();
        }

        // Update the payment method in Firestore
        await FirebaseFirestore.instance
            .collection('payment_methods')
            .doc(widget.paymentMethod.id)
            .update({
          'name': _nameController.text,
          'accountNumber': _accountNumberController.text,
          'imageUrl': imageUrl,
        });


        showToastService(context:context,message: 'تم تحديث طريقة الدفع بنجاح',color: Colors.green ,iconData: Icons.check,);

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التحديث: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loader
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تعديل طريقة الدفع'),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Display the current image or the selected new image
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!) // Show the new selected image
                            : (widget.paymentMethod.imageUrl.isNotEmpty
                            ? NetworkImage(widget.paymentMethod.imageUrl)
                        // Show the current image
                            : null), // Show a placeholder if no image is available
                        child: _imageFile == null && widget.paymentMethod.imageUrl.isEmpty
                            ? Icon(Icons.camera_alt, size: 40) // Placeholder icon
                            : null,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'اسم طريقة الدفع'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال اسم طريقة الدفع';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _accountNumberController,
                      decoration: InputDecoration(labelText: 'رقم الحساب'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال رقم الحساب';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updatePaymentMethod, // Disable button when loading
                      child: Text('حفظ التغييرات'),
                    ),
                  ],
                ),
              ),
            ),
            // Show a loader when _isLoading is true
            if (_isLoading)
              buildSpinKitFadingCircle()
          ],
        ),
      ),
    );
  }
}