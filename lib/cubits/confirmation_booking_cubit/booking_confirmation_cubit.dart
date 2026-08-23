import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../models/payment_method_model/payment_method_model.dart';
import '../../modules/admin/add_payment_method_screen/add_payment_method_screen.dart';
import 'booking_confirmation_state.dart';

class BookingConfirmationCubit extends Cubit<BookingConfirmationState> {
  BookingConfirmationCubit() : super(BookingInitialState());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Data managed by the cubit
  TimeOfDay? selectedTime;
  File? paymentImage; // Store the selected image file

  // Parse time string
  TimeOfDay parseTime(String time) {
    try {
      final parts = time.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      if (parts[1].toUpperCase() == 'PM' && hour != 12) {
        hour += 12;
      } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      throw Exception('Error parsing time: $time');
    }
  }

  // Check if time is available
  bool isTimeAvailable(TimeOfDay selected, TimeOfDay start, TimeOfDay end) {
    final selectedMinutes = selected.hour * 60 + selected.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return selectedMinutes >= startMinutes && selectedMinutes <= endMinutes;
  }

  // Update selected time
  void updateSelectedTime(TimeOfDay time) {
    selectedTime = time;
    emit(BookingTimeUpdatedState());
  }

  // Set payment image
  void setPaymentImage(File image) {
    paymentImage = image;
    emit(PaymentImageUpdatedState());
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImage(File image) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in.');

      final ref = _storage.ref().child('payment_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask;
      final downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Store booking details in Firebase
  Future<void> storeBookingDetails({
    required String day,
    required String startTime,
    required String endTime,
    required String providerId,
    required BuildContext context,
    required String serviceName,
    required String description,
    required PaymentMethod paymentMethod,
  }) async {
    emit(BookingLoadingState());
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in.');

      if (selectedTime == null) throw Exception('No time selected.');
      if (paymentImage == null) throw Exception('No payment image selected.');

      // Upload payment image
      final imageURL = await _uploadImage(paymentImage!);

      final formattedTime = selectedTime!.format(context);

      final bookingData = {
        'userId': user.uid,
        'providerId': providerId,
        'day': day,
        'serviceName': serviceName,
        'description': description,
        'paymentMethodName': paymentMethod.name,
        'startTime': startTime,
        'endTime': endTime,
        'selectedTime': formattedTime,
        'paymentImageURL': imageURL, // Add payment image URL
        'timestamp': FieldValue.serverTimestamp(),
        'bookingConfirmed': false,
        'isBookingSeen': false,
      };

      await _firestore.collection('bookings').add(bookingData);

      emit(BookingSuccessState());

      // Clear data after successful booking
      // resetData();
    } catch (e) {
      emit(BookingErrorState('Failed to store booking: $e'));
    }
  }


  // List to store payment methods fetched from the backend or API.
  List<PaymentMethod> paymentMethods = [];

// Asynchronous function to fetch payment methods from a remote source.
// This function handles loading, success, and error states using a state management approach.
  Future<void> fetchPaymentMethods() async {
    try {
      // Emit a loading state to indicate that the payment methods are being fetched.
      // This is useful for showing a loading indicator in the UI.
      emit(BookingLoadingState());

      // Fetch payment methods from the backend or API using a static method `fetchPaymentMethods`
      // from the `PaymentMethod` class. The result is stored in the `paymentMethods` list.
      paymentMethods = await PaymentMethod.fetchPaymentMethods();

      // Emit a loaded state to indicate that the payment methods have been successfully fetched.
      // This is useful for updating the UI with the fetched data.
      emit(BookingLoadedState());
    } catch (e) {
      // If an error occurs during the fetch operation, emit an error state with a user-friendly message.
      // This is useful for showing an error message in the UI.
      emit(BookingErrorState('فشل تحميل طرق الدفع')); // Translation: "Failed to load payment methods"
    }
  }

  PaymentMethod? selectedPaymentMethod;
  void changeIndex(PaymentMethod index) {
    selectedPaymentMethod = index;
    emit(ChangePaymentMethodState());
  }

  bool isPaymentMethodsVisible = false;

  void togglePaymentMethodsVisibility() {
    isPaymentMethodsVisible = !isPaymentMethodsVisible; // Toggle visibility
    emit(BookingLoadedState()); // Emit a state to rebuild the UI
  }


  // Method to reset data
  void resetData() {
    selectedTime = null;
    paymentImage = null;
    emit(BookingInitialState()); // Reset to initial state
  }

}