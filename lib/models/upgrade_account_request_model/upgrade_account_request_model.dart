import 'package:cloud_firestore/cloud_firestore.dart';

class UpgradeRequestModel {
  final String userId;
  final String requestMessage;
  final String status;

  UpgradeRequestModel({
    required this.userId,
    required this.requestMessage,
    required this.status,
  });

  // Factory method to create a model from Firestore document data
  factory UpgradeRequestModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return UpgradeRequestModel(
      userId: data['userId'] ?? '',
      requestMessage: data['requestMessage'] ?? '',
      status: data['status'] ?? 'Pending',
    );
  }

  // Convert the model to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'requestMessage': requestMessage,
      'status': status,
    };
  }
}
