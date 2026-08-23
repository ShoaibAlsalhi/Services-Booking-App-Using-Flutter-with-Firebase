import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:service_booking_app/shared/styles/colors.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/fcm/v1.dart' as fcm;
import '../../cubits/confirmation_booking_cubit/booking_confirmation_cubit.dart';
import '../../cubits/confirmation_booking_cubit/booking_confirmation_state.dart';
import '../../models/payment_method_model/payment_method_model.dart';
import '../../shared/components/components.dart';
import '../../shared/components/constants.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String day;
  final String startTime;
  final String endTime;
  final String providerId;
  final String serviceName;
  final String serviceDepositPrice;

  BookingConfirmationScreen({
    super.key,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.providerId,
    required this.serviceName,
    required this.serviceDepositPrice,
  });

  final descriptionController = TextEditingController();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> _pickTime(BuildContext context) async {
    final cubit = context.read<BookingConfirmationCubit>();
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: cubit.parseTime(startTime),
    );

    if (pickedTime != null) {
      cubit.updateSelectedTime(pickedTime);
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final cubit = context.read<BookingConfirmationCubit>();
      cubit.setPaymentImage(File(pickedFile.path));
    }
  }

  void _confirmBooking(BuildContext context) async {
    final cubit = context.read<BookingConfirmationCubit>();

    if (cubit.selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار وقت.')),
      );
      return;
    }

    if (descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال وصف للمشكلة.')),
      );
      return;
    }

    if (cubit.selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار طريقة دفع.')),
      );
      return;
    }

    final start = cubit.parseTime(startTime);
    final end = cubit.parseTime(endTime);

    if (cubit.isTimeAvailable(cubit.selectedTime!, start, end)) {
      await cubit.storeBookingDetails(
        day: day,
        startTime: startTime,
        endTime: endTime,
        providerId: providerId,
        context: context,
        serviceName: serviceName,
        description: descriptionController.text,
        paymentMethod: cubit.selectedPaymentMethod!,
      );

      // Fetch the provider's FCM token from Firestore
      final providerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(providerId)
          .get();
      final String? providerToken = providerDoc.data()?['fcmToken'];

      if (providerToken != null) {
        await sendFcmNotificationV1(
          providerToken: providerToken,
          serviceName: serviceName,
          day: day,
          selectedTime: cubit.selectedTime.toString()
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الوقت المختار ليس ضمن الساعات المتاحة.')),
      );
    }
  }

  void showPaymentDetailsDialog({required BuildContext context, required PaymentMethod paymentMethod}) {
    buildQuickAlertDialog(
      context: context,
      title: 'تفاصيل الدفع',
      message: 'طريقة الدفع: ${paymentMethod.name}\nرقم الحساب: ${paymentMethod.accountNumber}\nيرجى إرسال المبلغ إلى رقم الحساب أعلاه.',
      alertType: QuickAlertType.info,
      confirmBtnText: ' تم ',
      confirmBtnColor: Colors.blue,
      onConfirmBtnTap: () {
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingConfirmationCubit()..fetchPaymentMethods(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: defaultBackgroundColor,
          appBar: AppBar(
            title: const Text(' تأكيد عملية الحجز '),
            backgroundColor: Colors.white,
          ),
          body: BlocConsumer<BookingConfirmationCubit, BookingConfirmationState>(
            listener: (context, state) {
              if (state is BookingErrorState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              } else if (state is BookingSuccessState) {
                buildQuickAlertDialog(
                  context: context,
                  title: 'تفاصيل العملية',
                  message: ' تم تأكيد إجراء عملية الحجز  بنجاح \n وفي انتظار الموافقة من مقدم الخدمة ',
                  alertType: QuickAlertType.success,
                  confirmBtnText: ' العمليات ',
                  confirmBtnColor: Colors.green,
                  onConfirmBtnTap: () {
                    Navigator.pop(context);
                  },
                );
              }
            },
            builder: (context, state) {
              final cubit = context.read<BookingConfirmationCubit>();

              // Show loader if the state is BookingLoadingState
              if (state is BookingLoadingState) {
                return Center(
                  child: buildSpinKitFadingCircle(),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: AnimationLimiter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 500),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0, // Slide from the bottom
                          child: FadeInAnimation(
                            child: widget,
                          ),
                        ),
                        children: [
                          // Gradient Card for Day and Availability
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor: Colors.orange[50],
                                        child: Icon(
                                          Icons.calendar_today, // Icon for Day
                                          size: 26,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                      const SizedBox(width: 8), // Spacing between the icon and text
                                      Text(
                                        'اليوم: $day',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor: Colors.orange[50],
                                        child: Icon(
                                          Icons.access_time, // Icon for Day
                                          size: 26,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'من: ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                      Text(
                                        startTime,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.withOpacity(0.8),
                                        ),
                                      ),
                                      const SizedBox(width: 10), // Spacing between From and To
                                      Text(
                                        'إلى: ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                      Text(
                                        endTime,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    ' عربون مقدم لحجز الخدمة : $serviceDepositPrice',
                                    style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                  Divider(color: Colors.green),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'تحديد الوقت',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: cubit.selectedTime != null
                                  ? cubit.selectedTime!.format(context)
                                  : 'قم بتحديد وقت الحجز',
                            ),
                            onTap: state is BookingLoadingState
                                ? null // Disable field tap while loading
                                : () => _pickTime(context),
                            style: TextStyle(fontSize: 18, color: textColor),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: state is BookingLoadingState ? Colors.grey : Colors.teal, // Change border color when loading
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.deepOrange[300]!,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.access_time, color: Colors.red),
                              hintText: 'Tap to choose time',
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Description Field
                          Text(
                            'وصف المشكلة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: descriptionController,
                            maxLines: 4, // Allow multiple lines for description
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.teal,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.deepOrange[300]!,
                                  width: 2,
                                ),
                              ),
                              hintText: 'قم بوصف المشكلة التي تريد حلها...',
                              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.8)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Toggle Button to Show/Hide Payment Methods
                          InkWell(
                            onTap: () => cubit.togglePaymentMethodsVisibility(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'أنقر لعرض طرق الدفع',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    cubit.isPaymentMethodsVisible
                                        ? Icons.keyboard_arrow_up_sharp
                                        : Icons.keyboard_arrow_down_sharp,
                                    color: Colors.deepOrange,
                                    size: 30,
                                  ),
                                  onPressed: () {
                                    cubit.togglePaymentMethodsVisibility(); // Toggle visibility
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Payment Method Section (Conditionally Visible)
                          Visibility(
                            visible: cubit.isPaymentMethodsVisible,
                            child: Column(
                              children: cubit.paymentMethods.map((PaymentMethod method) {
                                return RadioListTile<PaymentMethod>(
                                  activeColor: Colors.red,
                                  title: Row(
                                    children: [
                                      // Display the payment method image as a circle
                                      if (method.imageUrl != null)
                                        ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: method.imageUrl, // URL of the image
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => buildSpinKitFadingCircle(), // Placeholder while loading
                                            errorWidget: (context, url, error) => Icon(Icons.attach_money, color: Colors.deepOrange), // Error handling
                                          ),
                                        ),
                                      // Display the name of the payment method
                                      const SizedBox(width: 15),
                                      Text(method.name),
                                    ],
                                  ),
                                  value: method,
                                  groupValue: cubit.selectedPaymentMethod,
                                  onChanged: (PaymentMethod? value) {
                                    cubit.changeIndex(value!);
                                    showPaymentDetailsDialog(context: context, paymentMethod: value);
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          const Divider(thickness: 2),
                          const SizedBox(height: 20),
                          // Payment Image Section
                          Text(
                            ' قم بإرفاق صورة إثبات الدفع ',
                            style: TextStyle(fontSize: 18, color: textColor),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: state is BookingLoadingState
                                ? null // Disable tap while loading
                                : () => _pickImage(context),
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                image: cubit.paymentImage != null
                                    ? DecorationImage(
                                  image: FileImage(cubit.paymentImage!),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: cubit.paymentImage == null
                                  ? const Icon(
                                Icons.upload,
                                size: 40,
                                color: Colors.red,
                              )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Confirm Booking Button
                          Center(
                            child: buildElevatedButton(
                              onPressed: () {
                                if (state is BookingLoadingState) null;
                                _confirmBooking(context);
                              },
                              width: 300,
                              child: const Text(
                                'تأكيد الحجز ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  Future<void> sendFcmNotificationV1({
    required String providerToken,
    required String serviceName,
    required String selectedTime,
    required String day,
  }) async {
    // Load the service account credentials
    final serviceAccountCredentials = await loadServiceAccountCredentials();

    // Authenticate and get the OAuth2 access token
    final client = await auth.clientViaServiceAccount(
      serviceAccountCredentials,
      [fcm.FirebaseCloudMessagingApi.cloudPlatformScope],
    );

    // Initialize the FCM API
    final fcmApi = fcm.FirebaseCloudMessagingApi(client);

    // Create the FCM message
    final message = fcm.Message(
      token: providerToken,
      notification: fcm.Notification(
        title: 'حجز جديد',
        body: 'تم استلام حجز جديد لخدمة $serviceName\nالوقت: $selectedTime\nاليوم: $day',
      ),
      data: {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'id': '1',
        'status': 'done',
        'screen': 'BookingScreen',
        'selectedTime': selectedTime,
        'day': day,
      },
    );

    // Send the message
    try {
      final response = await fcmApi.projects.messages.send(
        fcm.SendMessageRequest(message: message),
        'projects/deliveryapp-77614', // Replace with your Firebase project ID
      );

      if (kDebugMode) {
        print("FCM Response: ${response.name}");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
    } finally {
      client.close();
    }
  }


  Future<auth.ServiceAccountCredentials> loadServiceAccountCredentials() async {
    final jsonString = await rootBundle.loadString('assets/service-account-key.json');
    return auth.ServiceAccountCredentials.fromJson(json.decode(jsonString));
  }
}