import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Authentication

import '../../../models/service_provider/service_provider_model.dart';
import '../../../shared/components/components.dart';
import '../../../shared/styles/colors.dart';
import '../../login/login_screen.dart';
import '../../sign_up/sign_up_screen.dart';
import '../booking_confirmation_screen.dart';

class ProviderAvailabilityScreen extends StatelessWidget {
  final ServiceProviderModel serviceProvider;
  final String serviceName;
  final String serviceDepositPrice;

  const ProviderAvailabilityScreen({
    Key? key,
    required this.serviceName,
    required this.serviceProvider,
    required this.serviceDepositPrice,
  }) : super(key: key);

  // Function to check if the user is logged in
  Future<bool> isUserLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    return user != null; // Returns true if the user is logged in
  }

  // Show a dialog to prompt the user to log in or sign up

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        appBar: AppBar(
          title: const Text('أوقات توفر مقدم الخدمة'),
          leading: IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.red[50],
              child: const Icon(
                Icons.arrow_back,
                color: Colors.red,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvailabilityList(),
            ],
          ),
        ),
      ),
    );
  }

  // Build availability list
  Widget _buildAvailabilityList() {
    if (serviceProvider.availability.isEmpty) {
      return const Center(child: Text('لم يتم توفير معلومات التوفر.'));
    }

    // Define the order of the days of the week starting from Saturday
    List<String> daysOfWeekOrder = [
      'السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'
    ];

    // Sort the availability map by the order of days in the week
    List<String> sortedDays = [];
    for (var day in daysOfWeekOrder) {
      if (serviceProvider.availability.containsKey(day)) {
        sortedDays.add(day);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimationLimiter(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.80
            ),
            itemCount: sortedDays.length,
            itemBuilder: (context, index) {
              String day = sortedDays[index];
              Map<String, dynamic> times = serviceProvider.availability[day];
              bool isDayOff = times['dayIsOff'] ?? false;

              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 500),
                columnCount: 2,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: GestureDetector(
                      onTap: () async {
                        if (isDayOff) {
                          showToastService(
                            context: context,
                            message: ' هذا اليوم غير متاح. يرجى اختيار يوم آخر.',
                            color: Colors.orange,
                            iconData: Icons.warning_amber_rounded,
                          );
                        } else {
                          // Check if the user is logged in
                          final isLoggedIn = await isUserLoggedIn();
                          if (!isLoggedIn) {
                            // If the user is not logged in, show the login/sign-up dialog
                            showLoginSignUpDialog(context);
                            return;
                          }

                          // If the user is logged in, proceed to the booking confirmation screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingConfirmationScreen(
                                day: day,
                                startTime: times['startTime'],
                                endTime: times['endTime'],
                                providerId: serviceProvider.id,
                                serviceName: serviceName,
                                serviceDepositPrice: serviceDepositPrice,
                              ),
                            ),
                          );
                        }
                      },
                      child: Stack(
                        children: [
                          SizedBox(
                            height: 500, // Adjust the height to your preferred value
                            child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: isDayOff ? Colors.white : Colors.white,
                                ),
                                child: Stack(
                                  children: [
                                    // Center the calendar icon at the top
                                    Positioned(
                                      top: 8,
                                      left: 0,
                                      right: 0,
                                      child: Align(
                                        alignment: Alignment.topCenter, // Center the icon horizontally
                                        child: CircleAvatar(
                                          backgroundColor: isDayOff ? Colors.red[50] : Colors.orange[50],
                                          radius: 35,
                                          child: Icon(
                                            isDayOff ? Icons.event_busy : Icons.event, // Use calendar icons
                                            color: isDayOff ? Colors.red : Colors.orange,
                                            size: 50,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Center the text and other widgets
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                day.toUpperCase(),
                                                style: TextStyle(
                                                  color: isDayOff ? Colors.red : Colors.blue[900],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Flexible(
                                              child: Text(
                                                isDayOff
                                                    ? 'غير متوفر حاليًا'
                                                    : '${times['startTime']} - ${times['endTime']}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDayOff ? Colors.red : Colors.blue[800],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Bottom button
                                    Positioned(
                                      bottom: 8,
                                      left: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isDayOff ? Colors.red : Colors.orange,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          isDayOff ? 'غير متاح' : 'احجز الآن', // Modify text based on day availability in Arabic
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}