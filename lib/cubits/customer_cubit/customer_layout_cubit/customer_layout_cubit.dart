import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../modules/customer/customer_list_category_screen.dart';
import '../../../modules/customer/bookings/view_customer_bookings_screen.dart';
import '../../../modules/customer/customer_list_services_screen.dart';
import '../../../modules/customer/upgrade_account/upgrade_account_screen.dart';
import '../../../modules/logout/logoutscreen.dart';
import '../../../modules/user_profile_screen/user_profile_screen.dart';
import 'customer_layout_state.dart';

class CustomerLayoutCubit extends Cubit<CustomerLayoutStates> {
  CustomerLayoutCubit() : super(CustomerLayoutInitialState()) {
    // Initialize userId when the cubit is created
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  // to create an object from the cubit to use it in all the application
  static CustomerLayoutCubit get(context) => BlocProvider.of(context);

  late String userId;
  int customerCurrentIndex = 0;

  // Screens for the customer
  List<Widget> get customerScreens => [
    CustomerListCategoryScreen(),
    CustomerBookingsScreen(), // Corrected the screen instantiation
    UserProfileScreen(),
    UpgradeAccountRequestScreen(customerId: userId),
  ];

  // Titles for the customer screens
  List<String> customerScreensTitles = [
    'الفئات',
    'حجوزاتي',
    'الملف الشخصي',
    'ترقية الحساب ',
  ];

  // Method to change the current index for the bottom navigation
  void changeIndex(int index) {
    customerCurrentIndex = index;
    emit(ChangeCustomerBottomNavigationBarState());
  }
}