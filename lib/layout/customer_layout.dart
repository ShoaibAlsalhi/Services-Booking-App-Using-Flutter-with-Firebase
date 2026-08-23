import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Authentication

import '../cubits/customer_cubit/customer_cubit.dart';
import '../cubits/customer_cubit/customer_layout_cubit/customer_layout_cubit.dart';
import '../cubits/customer_cubit/customer_layout_cubit/customer_layout_state.dart';

import '../cubits/customer_cubit/sub_cubits/category_cubit/category_cubit.dart';
import '../modules/customer/customer_list_category_screen.dart';
import '../modules/login/login_screen.dart';
import '../shared/components/classes.dart';
import '../shared/components/components.dart';

class CustomerLayout extends StatelessWidget {
  const CustomerLayout({super.key});

  // Function to check if the user is logged in
  Future<bool> isUserLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    return user != null; // Returns true if the user is logged in
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerLayoutCubit, CustomerLayoutStates>(
      listener: (BuildContext context, CustomerLayoutStates state) {},
      builder: (BuildContext context, CustomerLayoutStates state) {
        CustomerLayoutCubit cubit = CustomerLayoutCubit.get(context);
        CategoryCubit categoryCubit = CategoryCubit.get(context);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: Text(cubit.customerScreensTitles[cubit.customerCurrentIndex]),
              actions: [
                if (cubit.customerScreens[cubit.customerCurrentIndex] is CustomerListCategoryScreen)
                  IconButton(
                    icon: CircleAvatar(
                      backgroundColor: Colors.red[50],
                      child: Icon(Icons.search, color: Colors.red),
                    ),
                    onPressed: () {
                      // Check if categories is loaded
                      if (categoryCubit.categories.isEmpty) {
                        // Optionally load categories if not loaded
                        categoryCubit.fetchCategoriesRealTime();
                        // Show a message or loading indicator
                        // showToast(text: 'Loading categories...', state: ToastStates.WARNING);
                        return;
                      }

                      showSearch(
                        context: context,
                        delegate: CategoriesSearchDelegate(
                          categories: categoryCubit.categories ?? [], // Provide empty list if null
                        ),
                      );
                    },
                  ),              ],
            ),
            body: cubit.customerScreens[cubit.customerCurrentIndex],

            // Replace BottomNavigationBar with CurvedNavigationBar
            bottomNavigationBar: CurvedNavigationBar(
              index: cubit.customerCurrentIndex,
              onTap: (index) async {
                // Allow access to the first index (Home screen) and second index without login
                if (index != 0) {
                  // Check if the user is logged in before allowing navigation
                  final isLoggedIn = await isUserLoggedIn();
                  if (!isLoggedIn) {
                    // If the user is not logged in, navigate to the login screen
                    navigateTo(context, LoginScreen());
                    return; // Stop further execution
                  }
                }

                // If the user is logged in or accessing an allowed screen, proceed with the navigation
                cubit.changeIndex(index);
              },
              height: 60, // Height of the curved navigation bar
              color: Colors.white, // Background color of the navigation bar
              buttonBackgroundColor: Colors.orange[50], // Color of the selected icon's button
              backgroundColor: Colors.grey.shade200, // Background color of the bar
              animationDuration: Duration(milliseconds: 300), // Animation duration
              items: [
                Icon(
                  Icons.home,
                  size: 30,
                  color: cubit.customerCurrentIndex == 0 ? Colors.deepOrange : Colors.black,
                ),
                Icon(
                  Icons.book_online_outlined,
                  size: 30,
                  color: cubit.customerCurrentIndex == 1 ? Colors.deepOrange : Colors.black,
                ),
                Icon(
                  Icons.person,
                  size: 30,
                  color: cubit.customerCurrentIndex == 2 ? Colors.deepOrange : Colors.black,
                ),
                Icon(
                  Icons.developer_board,
                  size: 30,
                  color: cubit.customerCurrentIndex == 3 ? Colors.deepOrange : Colors.black,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

