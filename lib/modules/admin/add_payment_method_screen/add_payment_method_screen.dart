import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:service_booking_app/shared/components/components.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  @override
  _AddPaymentMethodScreenState createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _paymentImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _addPaymentMethod() async {
    String name = _nameController.text.trim();
    String accountNumber = _accountNumberController.text.trim();

    if (name.isNotEmpty && accountNumber.isNotEmpty && _paymentImage != null) {
      // تحميل الصورة إلى Firebase Storage
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = _storage.ref().child('payment_images/$fileName');
      UploadTask uploadTask = storageRef.putFile(_paymentImage!);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      // إضافة طريقة الدفع إلى Firestore
      DocumentReference docRef = _firestore.collection('payment_methods').doc(); // إنشاء معرف المستند

      await docRef.set({
        'id': docRef.id, // تخزين معرف المستند الذي تم إنشاؤه
        'name': name,
        'account_number': accountNumber,
        'image_url': imageUrl, // تخزين رابط الصورة
        'created_at': FieldValue.serverTimestamp(),
      });

      showToastService(context:context,message: 'تمت إضافة طريقة الدفع بنجاح!',color: Colors.green ,iconData: Icons.check,);


      _nameController.clear();
      _accountNumberController.clear();
      setState(() {
        _paymentImage = null; // إعادة تعيين الصورة المحددة
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى ملء جميع الحقول وتحديد صورة.')),
      );

    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _paymentImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('إضافة طريقة دفع')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الحساب',
                    labelStyle: TextStyle(
                      color: Colors.deepOrange, // لون النص الطافي (Label)
                    ),
                    hintText: 'أدخل اسم الحساب', // نص تلميح داخل الحقل
                    hintStyle: TextStyle(
                      color: Colors.grey, // لون نص التلميح
                    ),
                    filled: true, // تفعيل تعبئة الخلفية
                    fillColor: Colors.grey[100], // لون خلفية الحقل
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.deepOrange, // لون الحدود عندما يكون الحقل غير نشط
                      ),
                      borderRadius: BorderRadius.circular(10), // زوايا دائرية
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.green, // لون الحدود عندما يكون الحقل نشطًا
                      ),
                      borderRadius: BorderRadius.circular(10), // زوايا دائرية
                    ),
                  ),
                  style: TextStyle(
                    color: Colors.black, // لون النص الذي يتم إدخاله
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _accountNumberController,
                  decoration: InputDecoration(
                    labelText: 'رقم الحساب',
                    labelStyle: TextStyle(
                      color: Colors.deepOrange, // لون النص الطافي (Label)
                    ),
                    hintText: 'أدخل رقم الحساب', // نص تلميح داخل الحقل
                    hintStyle: TextStyle(
                      color: Colors.grey, // لون نص التلميح
                    ),
                    filled: true, // تفعيل تعبئة الخلفية
                    fillColor: Colors.grey[200], // لون خلفية الحقل
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.deepOrange, // لون الحدود عندما يكون الحقل غير نشط
                      ),
                      borderRadius: BorderRadius.circular(10), // زوايا دائرية
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.green, // لون الحدود عندما يكون الحقل نشطًا
                      ),
                      borderRadius: BorderRadius.circular(10), // زوايا دائرية
                    ),
                  ),
                  style: TextStyle(
                    color: Colors.black, // لون النص الذي يتم إدخاله
                  ),
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: _paymentImage == null
                        ? Icon(Icons.camera_alt, color: Colors.grey)
                        : Image.file(
                      _paymentImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 100),
                buildElevatedButton(onPressed: _addPaymentMethod, child: Text('إضافة طريقة دفع'),width: 300,height: 50)
              ],
            ),
          ),
        ),
      ),
    );
  }
}