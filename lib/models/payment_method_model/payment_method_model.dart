import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethod {
  final String id;
  final String name;
  final String accountNumber;
  final String imageUrl;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.imageUrl,
    required this.createdAt,
  });

  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PaymentMethod(
      id: doc.id,
      name: data['name'] ?? '',
      accountNumber: data['account_number'] ?? '',
      imageUrl: data['image_url'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Future<List<PaymentMethod>> fetchPaymentMethods() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('payment_methods').orderBy('created_at', descending: true).get();
    return snapshot.docs.map((doc) => PaymentMethod.fromFirestore(doc)).toList();
  }
}
