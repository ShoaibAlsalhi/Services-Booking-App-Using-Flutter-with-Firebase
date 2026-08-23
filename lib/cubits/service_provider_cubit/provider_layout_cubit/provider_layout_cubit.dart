import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_booking_app/cubits/service_provider_cubit/provider_layout_cubit/provider_layout_state.dart';
import 'package:service_booking_app/modules/service_provider/manage_availability_screen.dart';

import '../../../modules/reports_screen/reports_screen.dart';
import '../../../modules/service_provider/manage_booking_screen/manage_booking_screen.dart';
import '../../../modules/service_provider/service_provider_reviews_screen.dart';
import '../../../modules/service_provider/service_provider_screen.dart';
import '../../../modules/user_profile_screen/user_profile_screen.dart';

class ProviderLayoutCubit extends Cubit<ProviderLayoutStates> {
  ProviderLayoutCubit() : super(ProviderLayoutInitialState());

  // To create an object from the cubit to use it in all the application
  static ProviderLayoutCubit get(context) => BlocProvider.of(context);

  int providerCurrentIndex = 0;
  int unseenBookingsCount = 0; // To store the count of unseen bookings

  // Screens for the service provider
  List<Widget> providerScreens = [
    ServiceProviderScreen(),
    ServiceProviderReportsScreen(
        serviceProviderId: FirebaseAuth.instance.currentUser!.uid),
    ServiceProviderBookingsScreen(
        providerId: FirebaseAuth.instance.currentUser!.uid),
    ServiceProviderReviewsScreen(
        providerId: FirebaseAuth.instance.currentUser!.uid),
    UserProfileScreen(),
    AvailabilityScreen(providerId: FirebaseAuth.instance.currentUser!.uid),
  ];

  // Titles for the service provider screens
  List<String> providerScreensTitles = [
    ' لوحة تحكم مقدم الخدمة ',
    ' تقارير الأداء ',
    'مواعيد العملاء ',
    ' مراجعة تعليقات العملاء ',
    'الملف الشخصي',
    ' إدارة جدول التوفر '
  ];

  // Method to change the current index for the bottom navigation
  void changeIndex(int index) {
    providerCurrentIndex = index;
    emit(ChangeProviderBottomNavigationBarState());
  }

  // Firestore subscription for unseen bookings
  StreamSubscription<QuerySnapshot>? _unseenBookingsSubscription;

  // Get the total count of unseen bookings (isBookingSeen = false)
  void getUnseenBookingsCount() {
    _unseenBookingsSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('isBookingSeen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      unseenBookingsCount = snapshot.docs.length;
      emit(UnseenBookingsCountUpdated()); // Emit state for UI update
    }, onError: (e) {
      unseenBookingsCount = 0;
      emit(UnseenBookingsCountUpdated()); // Emit state for UI update
    });
  }

  // Cancel the Firestore subscription when the Cubit is closed
  @override
  Future<void> close() {
    _unseenBookingsSubscription?.cancel(); // Cancel the subscription
    return super.close();
  }



}
