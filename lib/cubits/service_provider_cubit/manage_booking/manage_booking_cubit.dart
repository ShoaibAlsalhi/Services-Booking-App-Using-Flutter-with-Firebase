import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/booking_model/booking_model.dart';
import '../../../models/user_model/user_model.dart';
import 'manage_booking_state.dart';

class ProviderBookingCubit extends Cubit<ProviderBookingState> {
  final String providerId;
  StreamSubscription? _bookingsSubscription; // To manage the real-time subscription

  ProviderBookingCubit(this.providerId) : super(BookingLoading());
  static ProviderBookingCubit get(context) => BlocProvider.of(context);

  @override
  Future<void> close() {
    _bookingsSubscription?.cancel(); // Cancel the subscription when the cubit is closed
    return super.close();
  }

  // Fetch real-time bookings for the service provider
  void fetchBookings(String providerId) {
    emit(BookingWaiting()); // Emit waiting state before starting the fetch process

    _bookingsSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .listen((snapshot) async {
      try {
        final bookings = await Future.wait(snapshot.docs.map((doc) async {
          var booking = BookingModel.fromFirestore(doc);

          // Fetch user data to get customer name
          var userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(booking.userId)
              .get();

          var user = UserModel.fromFirestore(booking.userId, userSnapshot.data()!);
          booking.customerName = user.name;

          // Fetch provider data from the users collection to get provider name
          var providerSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(booking.providerId)
              .get();

          var providerData = providerSnapshot.data();
          if (providerData != null && providerData.containsKey('providerName')) {
            booking.providerName = providerData['providerName'];
          }

          return booking;
        }).toList());

        emit(BookingLoaded(bookings)); // Emit the loaded state with the updated bookings
      } catch (e) {
        emit(BookingError('Failed to load bookings: $e'));
      }
    }, onError: (error) {
      emit(BookingError('Failed to load bookings: $error'));
    });
  }

  // Fetch real-time bookings for a specific customer
  void fetchBookingsForCustomer(String customerId) {
    emit(BookingWaiting()); // Emit waiting state before starting the fetch process

    _bookingsSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: customerId)
        .snapshots()
        .listen((snapshot) async {
      try {
        final bookings = await Future.wait(snapshot.docs.map((doc) async {
          var booking = BookingModel.fromFirestore(doc);

          // Fetch customer name using the userId from the bookings collection
          var userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(booking.userId)
              .get();
          var user = UserModel.fromFirestore(booking.userId, userSnapshot.data()!);

          booking.customerName = user.name; // Add the customer name to the booking

          // Fetch provider name using the providerId from the bookings collection
          var providerSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(booking.providerId)
              .get();
          var providerData = providerSnapshot.data();

          if (providerData != null && providerData.containsKey('providerName')) {
            booking.providerName = providerData['providerName']; // Set the provider name
          }

          return booking;
        }).toList());

        emit(BookingLoaded(bookings)); // Emit the loaded state with the updated bookings
      } catch (e) {
        emit(BookingError('Failed to load bookings for customer: $e'));
      }
    }, onError: (error) {
      emit(BookingError('Failed to load bookings for customer: $error'));
    });
  }

  // Fetch real-time bookings for a specific customer and provider
  void fetchBookingsForCustomerAndProvider(String customerId, String providerId) {
    emit(BookingWaiting()); // Emit waiting state before starting the fetch process

    _bookingsSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: customerId)
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .listen((snapshot) async {
      try {
        final bookings = await Future.wait(snapshot.docs.map((doc) async {
          var booking = BookingModel.fromFirestore(doc);

          // Fetch customer and provider names
          var userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(booking.userId)
              .get();
          var user = UserModel.fromFirestore(booking.userId, userSnapshot.data()!);
          booking.customerName = user.name;

          var providerSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(booking.providerId)
              .get();
          var providerData = providerSnapshot.data();
          if (providerData != null && providerData.containsKey('providerName')) {
            booking.providerName = providerData['providerName'];
          }

          return booking;
        }).toList());

        emit(BookingLoaded(bookings)); // Emit the loaded state with the updated bookings
      } catch (e) {
        emit(BookingError('Failed to load bookings: $e'));
      }
    }, onError: (error) {
      emit(BookingError('Failed to load bookings: $error'));
    });
  }
}