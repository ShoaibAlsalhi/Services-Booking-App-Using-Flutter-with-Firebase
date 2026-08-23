import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String bookingId;
  final String userId;
  final String providerId;
  final String serviceId;
  final String day;
  final String startTime;
  final String endTime;
  final bool bookingConfirmed;
  final String serviceName;
  String customerName; // Add customerName as a mutable field
  final bool isConfirmed;
  final bool isBookingSeen;
  final Timestamp timestamp;

  // These fields will be added after fetching related data
  String providerName = ''; // Add providerName field (to be set later)
  String userImageUrl = ''; // Add providerName field (to be set later)
  String selectedTime = ''; // Add selectedTime field (to be set later)
  String description = '';
  String paymentImageURL = ''; // Add paymentImageURL field for the payment proof image
  String paymentMethodName = ''; // Add paymentImageURL field for the payment proof image

  BookingModel({
    required this.bookingId,
    required this.userId,
    required this.providerId,
    required this.serviceId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.bookingConfirmed,
    required this.serviceName,
    this.customerName = '', // Initialize customerName with an empty string
    required this.isConfirmed,
    required this.isBookingSeen,
    required this.timestamp,
    this.paymentImageURL = '', // Initialize paymentImageURL with an empty string
    this.selectedTime = '', // Initialize paymentImageURL with an empty string
    this.description = '',
    this.paymentMethodName = '',
  });

  // Convert Firestore Document to BookingModel
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      bookingId: doc.id,
      userId: data['userId'] ?? '',
      providerId: data['providerId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      day: data['day'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      bookingConfirmed: data['bookingConfirmed'] ?? false,
      serviceName: data['serviceName'] ?? '',
      customerName: '', // Initially empty, to be filled later
      isConfirmed: data['bookingConfirmed'] ?? false,
      isBookingSeen: data['isBookingSeen'] ?? false,
      timestamp: data['timestamp'] ?? Timestamp.now(),
      paymentImageURL: data['paymentImageURL'] ?? '', // Add paymentImageURL
      selectedTime: data['selectedTime'] ?? '', // Add paymentImageURL
      description: data['description'] ?? '',
      paymentMethodName: data['paymentMethodName'] ?? '',
    );
  }


}