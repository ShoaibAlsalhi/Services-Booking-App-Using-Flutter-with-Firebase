import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../../models/booking_model/booking_model.dart';
import '../../../models/service_provider/service_provider_model.dart';
import '../../../shared/components/components.dart';
import '../../../shared/styles/colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Import animations package
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';


class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({Key? key}) : super(key: key);

  @override
  _CustomerBookingsScreenState createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  // Fetch customer bookings and their respective service provider names
  Stream<List<BookingModel>> fetchCustomerBookingsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      var bookings = await Future.wait(snapshot.docs.map((doc) async {
        var booking = BookingModel.fromFirestore(doc);

        // Fetch service provider details
        var providerSnapshot = await FirebaseFirestore.instance
            .collection('service_providers')
            .doc(booking.providerId)
            .get();

        var provider = ServiceProviderModel.fromFirestore(
            booking.providerId, providerSnapshot.data()!);

        // Fetch provider name from 'users' collection
        var userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(booking.providerId)
            .get();
        var providerName = userSnapshot.data()?['name'] ?? 'Unknown Provider';
        var providerImageUrl =
            userSnapshot.data()?['imageUrl'] ?? 'Unknown Provider';

        booking.providerName = providerName;
        booking.userImageUrl = providerImageUrl;
        return booking;
      }).toList());

      // Sort bookings by timestamp in descending order (most recent first)
      bookings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Remove duplicate providers (optional logic)
      var uniqueBookings = <BookingModel>[];
      var providerIds = <String>{};

      for (var booking in bookings) {
        if (!providerIds.contains(booking.providerId)) {
          uniqueBookings.add(booking);
          providerIds.add(booking.providerId);
        }
      }

      return uniqueBookings;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get current userId dynamically to reflect login/logout changes
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: defaultBackgroundColor,
      body: StreamBuilder<List<BookingModel>>(
        stream: fetchCustomerBookingsStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return buildSpinKitFadingCircle(); // Your custom loading spinner
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            var bookings = snapshot.data!;

            return AnimationLimiter(
              child: ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  var booking = bookings[index];

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: ScaleAnimation(
                          scale: 0.5,
                          child: Container(
                            padding: const EdgeInsets.all(15.0),
                            margin: const EdgeInsets.symmetric(
                                vertical: 3.0, horizontal: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingDetailsScreen(
                                      bookingId: booking.bookingId,
                                      providerId: booking.providerId,
                                      providerName: booking.providerName,
                                      userId: booking.userId,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  // Provider Image
                                  buildeCachedNetworkImage(
                                    url: booking.userImageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 15),
                                  // Booking Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking.providerName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'الخدمة: ${booking.serviceName}',
                                          style: const TextStyle(fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              'اليوم: ${booking.day}',
                                              style: const TextStyle(
                                                  fontSize: 15),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'الوقت: ${booking.selectedTime}',
                                              style: const TextStyle(
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  booking.bookingConfirmed
                                      ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 30,
                                  )
                                      : Icon(
                                    Icons.cancel,
                                    color: Colors.red[900],
                                    size: 30,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          } else {
            return const Center(child: Text('لا توجد حجوزات حالياً.'));
          }
        },
      ),
    );
  }
}

/////////////////////////////////////////////////////








class BookingDetailsScreen extends StatelessWidget {
  final String bookingId;
  final String providerId;
  final String providerName;
  final String userId; // Added userId

  const BookingDetailsScreen({
    Key? key,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    required this.userId, // Added userId to the constructor
  }) : super(key: key);

  Stream<List<BookingModel>> fetchBookingsForUserAndProvider(String providerId, String userId) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .where('userId', isEqualTo: userId) // Filter by userId
        .snapshots()
        .asyncMap((snapshot) async {
      var bookings = await Future.wait(snapshot.docs.map((doc) async {
        var booking = BookingModel.fromFirestore(doc);
        var providerSnapshot = await FirebaseFirestore.instance
            .collection('service_providers')
            .doc(booking.providerId)
            .get();
        return booking;
      }).toList());

      // Sort bookings by timestamp in descending order (most recent first)
      bookings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return bookings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        appBar: AppBar(
          backgroundColor: defaultBackgroundColor,
          title: const Text('تفاصيل الحجز'),
          elevation: 0,
        ),
        body: StreamBuilder<List<BookingModel>>(
          stream: fetchBookingsForUserAndProvider(providerId, userId), // Pass both providerId and userId
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return buildSpinKitFadingCircle();
            } else if (snapshot.hasError) {
              return Center(child: Text('خطأ: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              var bookings = snapshot.data!;

              return AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    var booking = bookings[index];

                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        horizontalOffset: 50.0, // Slide from the right
                        child: FadeInAnimation(
                          child: ScaleAnimation(
                            scale: 0.5, // Scale up from 50% to 100%
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      providerName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.right, // Align text to the right
                                    ),
                                    Divider(
                                      color: Colors.red[900], // Color of the divider
                                      thickness: 2, // Thickness of the line
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end, // Align subtitles to the right
                                  children: [
                                    _buildInfoRow(Icons.miscellaneous_services, 'الخدمة:', booking.serviceName),
                                    _buildInfoRow(Icons.calendar_today, 'اليوم:', booking.day),
                                    _buildInfoRow(Icons.timer, 'الوقت المحدد للعمل:', booking.selectedTime),
                                    _buildInfoRow(
                                      Icons.check_circle,
                                      'تم تأكيد الحجز:',
                                      booking.bookingConfirmed ? 'نعم' : 'لا',
                                    ),
                                    _buildInfoRow(
                                      Icons.visibility,
                                      'تم مشاهدة الحجز:',
                                      booking.isBookingSeen ? 'نعم' : 'لا',
                                    ),
                                    _buildInfoRow(Icons.payment, 'تم الدفع عبر:', booking.paymentMethodName),
                                    const SizedBox(height: 8),
                                    if (booking.paymentImageURL.isNotEmpty)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Colors.red[50],
                                                child: Icon(Icons.payment, size: 16, color: Colors.red[900]),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'صورة إثبات الدفع:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          InkWell(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return Dialog(
                                                    child: Image.network(
                                                      booking.paymentImageURL,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            child: buildeCachedNetworkImage(
                                                url: booking.paymentImageURL,
                                                height: 100,
                                                width: 100,
                                                fit: BoxFit.cover,
                                                borderRadius: 0
                                            ),
                                          ),
                                          const SizedBox(height: 30),
                                          ElevatedButton(
                                            onPressed: () {
                                              showDescriptionDialog(context, booking.description);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.deepOrange, // Button color
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text(
                                              'عرض وصف المشكلة',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Colors.red[50],
                                                child: Icon(Icons.access_time, size: 16, color: Colors.red[900]),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'وقت إجراء الحجز   : ${intl.DateFormat('HH:mm       yyyy-MM-dd').format(booking.timestamp.toDate().toLocal())}',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                trailing: booking.bookingConfirmed
                                    ? const Icon(Icons.check_circle, color: Colors.green, size: 30)
                                    : const Icon(Icons.cancel, color: Colors.red, size: 30),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            } else {
              return const Center(child: Text('لم يتم العثور على حجوزات.'));
            }
          },
        ),
      ),
    );
  }

  // Helper method to build info rows with icons
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.red[50],
            child: Icon(
              icon,
              color: Colors.red[900],
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 16,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to show description dialog
  void showDescriptionDialog(BuildContext context, String description) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('وصف المشكلة'),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }
}