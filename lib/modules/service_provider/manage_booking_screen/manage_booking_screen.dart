import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' as intl;
import 'package:service_booking_app/shared/styles/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../../../cubits/service_provider_cubit/manage_booking/manage_booking_cubit.dart';
import '../../../cubits/service_provider_cubit/manage_booking/manage_booking_state.dart';
import '../../../models/booking_model/booking_model.dart';
import '../../../models/user_model/user_model.dart';
import '../../../shared/components/components.dart';



class ServiceProviderBookingsScreen extends StatefulWidget {
  final String providerId;
  final bool isAdmin;

  const ServiceProviderBookingsScreen({
    Key? key,
    required this.providerId,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  _ServiceProviderBookingsScreenState createState() =>
      _ServiceProviderBookingsScreenState();
}

class _ServiceProviderBookingsScreenState
    extends State<ServiceProviderBookingsScreen> {
  Stream<List<BookingModel>> fetchBookingsStream(String providerId) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .asyncMap((snapshot) async {
      var bookings = await Future.wait(snapshot.docs.map((doc) async {
        var booking = BookingModel.fromFirestore(doc);

        var userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(booking.userId)
            .get();

        var user = UserModel.fromFirestore(booking.userId, userSnapshot.data()!);
        booking.customerName = user.name;

        return booking;
      }).toList());

      var uniqueBookings = <BookingModel>[];
      var customerIds = <String>{};

      for (var booking in bookings) {
        if (!customerIds.contains(booking.userId)) {
          uniqueBookings.add(booking);
          customerIds.add(booking.userId);
        }
      }

      return uniqueBookings;
    });
  }

  void updateBookingSeen(String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'isBookingSeen': true});
    } catch (error) {
      print('Error updating booking seen status: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        body: StreamBuilder<List<BookingModel>>(
          stream: fetchBookingsStream(widget.providerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return buildSpinKitFadingCircle();
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              var bookings = snapshot.data!;

              return ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  var booking = bookings[index];

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.deepOrange[50],
                        child: Icon(
                          Icons.person,
                          color: Colors.deepOrange,
                          size: 30,
                        ),
                      ),
                      title: Text(
                        booking.customerName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'خدمة: ${booking.serviceName}',
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'اليوم: ${booking.day}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      trailing: !booking.isBookingSeen
                          ? CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.teal[100],
                        child: Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 30,
                        ),
                      )
                          : CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.deepOrange[50],
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.deepOrange,
                          size: 23,
                        ),
                      ),
                      onTap: () {
                        if (!widget.isAdmin) updateBookingSeen(booking.bookingId);

                        // Navigate to CustomerBookingsScreen with providerId
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerBookingsScreen(
                              customerId: booking.userId,
                              customerName: booking.customerName,
                              providerId: widget.providerId,
                              isAdmin: widget.isAdmin,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            } else {
              return const Center(child: Text('No bookings found.'));
            }
          },
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////














class CustomerBookingsScreen extends StatelessWidget {
  final String customerId;
  final String customerName;
  final String providerId;
  final bool isAdmin;

  const CustomerBookingsScreen({
    Key? key,
    required this.customerId,
    required this.customerName,
    required this.providerId,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fetch bookings for the selected customer and provider
    context.read<ProviderBookingCubit>().fetchBookingsForCustomerAndProvider(customerId, providerId);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('حجوزات العميل $customerName'),
        ),
        body: BlocBuilder<ProviderBookingCubit, ProviderBookingState>(
          builder: (context, state) {
            if (state is BookingLoading) {
              return buildSpinKitFadingCircle();
            } else if (state is BookingWaiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildSpinKitFadingCircle(),
                    const SizedBox(height: 16),
                    const Text('جارٍ تحميل البيانات...'),
                  ],
                ),
              );
            } else if (state is BookingLoaded) {
              // Ensure only bookings for the specific customer and provider are displayed
              final customerBookings = state.bookings
                  .where((booking) =>
              booking.userId == customerId && booking.providerId == providerId)
                  .toList();

              if (customerBookings.isEmpty) {
                return const Center(child: Text('لا توجد حجوزات لهذا العميل.'));
              }

              return _buildCustomerBookingList(context, customerBookings);
            } else if (state is BookingError) {
              return Center(child: Text('حدث خطأ: ${state.errorMessage}'));
            }
            return const Center(child: Text('لا توجد بيانات.'));
          },
        ),
      ),
    );
  }

  Widget _buildCustomerBookingList(BuildContext context, List<BookingModel> bookings) {
    // Sort bookings by timestamp in descending order (most recent first)
    bookings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(context, booking);
      },
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking) {
    return _BookingCardWithTimer(booking: booking, isAdmin: isAdmin);
  }
}

class _BookingCardWithTimer extends StatefulWidget {
  final BookingModel booking;
  final bool isAdmin;

  const _BookingCardWithTimer({required this.booking, required this.isAdmin});

  @override
  _BookingCardWithTimerState createState() => _BookingCardWithTimerState();
}

class _BookingCardWithTimerState extends State<_BookingCardWithTimer> {
  Timer? _timer;
  Duration? _remainingTime;
  Duration? _totalDuration;
  bool _isToastShown = false; // To ensure toast is shown only once

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Update the remaining time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _calculateRemainingTime();
      });
    });
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    final bookingDate = widget.booking.timestamp.toDate().toLocal();
    final bookingDay = widget.booking.day;

    // Check if the current day matches the booking day and the current date is within 7 days of the booking timestamp
    final isSameDay = now.day == bookingDate.day && now.month == bookingDate.month && now.year == bookingDate.year;
    final isWithin7Days = now.difference(bookingDate).inDays <= 7;

    if (isSameDay && isWithin7Days) {
      final selectedTime = intl.DateFormat('HH:mm').parse(widget.booking.selectedTime);
      final selectedDateTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
      _remainingTime = selectedDateTime.difference(now);

      // Calculate total duration only once
      if (_totalDuration == null) {
        _totalDuration = selectedDateTime.difference(bookingDate);
      }

      // If the remaining time is negative, set it to zero
      if (_remainingTime!.isNegative) {
        _remainingTime = Duration.zero;
      }

      // Show toast when remaining time is 30% or less of the total duration
      if (_totalDuration != null && _remainingTime != null) {
        final thirtyPercentDuration = _totalDuration! * 0.3;
        if (_remainingTime! <= thirtyPercentDuration && !_isToastShown) {
          _isToastShown = true; // Ensure toast is shown only once
          Fluttertoast.showToast(
            msg: 'الوقت المتبقي أقل من 30%!',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      }
    } else {
      _remainingTime = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Name with Icon
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red[50],
                  child: Icon(Icons.miscellaneous_services, size: 20, color: Colors.red[900]),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.booking.serviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(thickness: 2, color: Colors.red[900]),
            // Booking Details with Icons
            _buildBookingDetailRow(Icons.calendar_today, 'اليوم: ${widget.booking.day}'),
            _buildBookingDetailRow(Icons.access_time, 'الوقت المحدد للعمل: ${widget.booking.selectedTime}'),
            _buildBookingDetailRow(Icons.check_circle, 'تم تأكيد الحجز: ${widget.booking.bookingConfirmed ? "نعم" : "لا"}'),
            _buildBookingDetailRow(Icons.payment, 'تم الدفع عبر: ${widget.booking.paymentMethodName}'),

            const SizedBox(height: 8),
            if (widget.booking.paymentImageURL.isNotEmpty) _buildPaymentImageSection(context, widget.booking),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                showDescriptionDialog(context, widget.booking.description);
              },
              icon: const Icon(Icons.description, color: Colors.white), // Icon before text
              label: const Text(
                'عرض وصف المشكلة',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.deepOrange, // Button color
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            _buildConfirmButton(context, widget.booking),
            const SizedBox(height: 20),

            Row(
              children: [
                CircleAvatar(
                    backgroundColor: Colors.red[50],
                    child: Icon(Icons.access_time, size: 16, color: Colors.red[900])
                ),
                const SizedBox(width: 8),
                Text(
                  'وقت إجراء الحجز   : ${intl.DateFormat('HH:mm       yyyy-MM-dd').format(widget.booking.timestamp.toDate().toLocal())}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            // Display remaining time if applicable
            if (_remainingTime != null && _remainingTime!.inSeconds > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'الوقت المتبقي: ${_remainingTime!.inHours} ساعات ${_remainingTime!.inMinutes.remainder(60)} دقائق ${_remainingTime!.inSeconds.remainder(60)} ثواني',
                  style: const TextStyle(fontSize: 14, color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.red[50],
            child: Icon(icon, size: 16, color: Colors.red[900]),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPaymentImageSection(BuildContext context, BookingModel booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBookingDetailRow(Icons.payment, 'صورة إثبات الدفع:'),
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
          child: Image.network(
            booking.paymentImageURL,
            height: 100,
            width: 100,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context, BookingModel booking) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (booking.bookingConfirmed)
          CircleAvatar(
            backgroundColor: Colors.green[50],
            child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
          )
        else
          if(widget.isAdmin)
            CircleAvatar(
              backgroundColor: Colors.red[50],
              child: const Icon(Icons.cancel, color: Colors.red, size: 24),
            ),
        if(!widget.isAdmin)
          ElevatedButton.icon(
            onPressed: () => _confirmBooking(context, booking),
            icon: const Icon(Icons.check, size: 16,color: Colors.white,),
            label: const Text('تأكيد الحجز'),
          ),
      ],
    );
  }

  Future<void> _confirmBooking(BuildContext context, BookingModel booking) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.bookingId)
          .update({'bookingConfirmed': true});

      final availabilityRef = FirebaseFirestore.instance
          .collection('service_providers')
          .doc(booking.providerId);

      await availabilityRef.set({
        'availability': {
          booking.day: {'dayIsOff': true},
        },
      }, SetOptions(merge: true));

      context.read<ProviderBookingCubit>().fetchBookingsForCustomer(booking.userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تأكيد الحجز وتحديث التوفر!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $error')),
      );
    }
  }
}