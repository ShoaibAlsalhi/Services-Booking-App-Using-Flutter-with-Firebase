import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:service_booking_app/shared/components/components.dart';
import 'package:service_booking_app/shared/network/local/cache_helper.dart';
import 'package:workmanager/workmanager.dart';

import 'cubits/account_upgrade_cubit/account_upgrade_cubit.dart';
import 'cubits/availability_cubit/availability_cubit.dart';
import 'cubits/confirmation_booking_cubit/booking_confirmation_cubit.dart';
import 'cubits/customer_cubit/customer_cubit.dart';
import 'cubits/customer_cubit/customer_layout_cubit/customer_layout_cubit.dart';
import 'cubits/customer_cubit/sub_cubits/Services_cubits/services_cubit.dart';
import 'cubits/customer_cubit/sub_cubits/category_cubit/category_cubit.dart';
import 'cubits/customer_cubit/sub_cubits/service_providers_cubit/service_providers_cubit.dart';
import 'cubits/login_cubit/login_cubit.dart';
import 'cubits/service_provider_cubit/manage_booking/manage_booking_cubit.dart';
import 'cubits/service_provider_cubit/provider_layout_cubit/provider_layout_cubit.dart';
import 'cubits/service_provider_cubit/service_provider_cubit.dart';
import 'cubits/sign_up_cubit/sign_up_cubit.dart';
import 'cubits/user_profile_cubit/user_profile_cubit.dart';
import 'firebase_options.dart';
import 'layout/customer_layout.dart';
import 'layout/provider_layout.dart';
import 'modules/account_blocked_screen/account_blocked_screen.dart';
import 'modules/admin/admin_screen.dart';
import 'modules/login/login_screen.dart';
import 'modules/on_boanding/on_boanding_screen.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'showReminderNotification') {
      final remainingTime = inputData?['remainingTime']; // Access the remaining time from inputData
      if (remainingTime != null) {
        // Show notification using flutter_local_notifications
        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

        const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'reminder_channel', // Channel ID
          'Booking Reminder', // Channel Name
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        );

        const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

        await flutterLocalNotificationsPlugin.show(
          0, // Notification ID
          'تنبيه الحجز', // Notification Title
          'الوقت المتبقي: $remainingTime دقائق', // Notification Body with remaining time
          platformChannelSpecifics,
        );
      } else {
        print('Remaining time is null'); // Debugging
      }
    }
    return Future.value(true);
  });
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await CacheHelper.init();

  await setupFCM();
  // Initialize Workmanager
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Set to false in production
  );
  runApp(MyApp());
}

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> setupFCM() async {
  // Request permission for notifications
  NotificationSettings settings = await _firebaseMessaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    if (kDebugMode) {
      print('User granted permission for notifications');
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Listen for incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Received a message while in the foreground: ${message.notification?.title}');
        _showNotification(message);
      }

    });

    // Handle messages when the app is in the background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('App opened from a notification: ${message.notification?.title}');
        _showNotification(message);
      }

      // Navigate to a specific screen if needed
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get the FCM token
    String? token = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print("FCM Token: $token");
    }

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print("New FCM Token: $newToken");
      }
      _saveTokenToFirestore(newToken);
    });

    // Save the token to Firestore (if needed)
    await _saveTokenToFirestore(token);
  } else {
    if (kDebugMode) {
      print('User denied permission for notifications');
    }
  }
}
Future<void> _saveTokenToFirestore(String? token) async {
  if (token == null) return;

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'fcmToken': token});
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
  _showNotification(message);
}

Future<void> _showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'service', // Channel ID
    'services', // Channel Name
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );
  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  await _flutterLocalNotificationsPlugin.show(
    0, // Notification ID
    message.notification?.title, // Title
    message.notification?.body, // Body
    platformChannelSpecifics,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    // Check if the user is already authenticated
    if (user != null) {
      final userId = user.uid;

      try {
        // Fetch user data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          final userRole = userData?['userRole'];
          final isBlocked = userData?['account_status'] == false;

          // Check if the account is blocked
          if (isBlocked) {
            showToastService(
              context: context,
              message: 'Your account is blocked. Please contact support.',
              color: Colors.red,
              iconData: Icons.error_outline,
            );
            return const AccountBlockedScreen(); // Navigate to AccountBlockedScreen
          }

          // Navigate to the corresponding screen based on the user's role
          switch (userRole) {
            case 'customer':
              // return const AdvertisementsListScreen();
              return const CustomerLayout();
            case 'service_provider':
              return ProviderLayout(
                providerId: userId,
              );
            case 'admin':
              return const AdminDashboardScreen();
            default:
              return const LoginScreen(); // Fallback to login if the role is unknown
          }
        }
      } catch (error) {
        // Handle error (e.g., Firestore fetching issues)
        debugPrint('Error fetching user data: $error');
      }
    }

    // If the user is not authenticated, show the login or onboarding screen
    bool? onBoarding = await CacheHelper.getData(key: 'OnBoarding');
    if (onBoarding != null) {
      return const CustomerLayout();
    } else {
      return OnBoardingScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SignUpCubit()),
        BlocProvider(create: (context) => CustomerLayoutCubit()),
        BlocProvider(create: (context) => ProviderLayoutCubit()..getUnseenBookingsCount()),
        BlocProvider(create: (context) => LoginCubit()),
        BlocProvider(create: (context) => ServiceProviderCubit()),
        BlocProvider(create: (context) => CustomerServiceProviderCubit()),
        BlocProvider(create: (context) => CategoryCubit()),
        BlocProvider(create: (context) => ServiceCubit()),
        BlocProvider(
          create: (context) => AvailabilityCubit(
              providerId: FirebaseAuth.instance.currentUser?.uid ?? ""),
        ),
        BlocProvider(create: (context) => BookingConfirmationCubit()),
        BlocProvider(
            create: (context) => ProviderBookingCubit(FirebaseAuth.instance.currentUser?.uid ?? "")),
        BlocProvider(create: (context) => UserProfileCubit()),
        BlocProvider(create: (context) => RequestCubit()),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Colors.blue,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontFamily: 'myFont'),
            bodyMedium: TextStyle(fontFamily: 'myFont'),
            bodySmall: TextStyle(fontFamily: 'myFont'),
            labelLarge: TextStyle(fontFamily: 'myFont'),
            titleLarge: TextStyle(fontFamily: 'myFont', fontSize: 19),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF143153),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          primarySwatch: Colors.blue,
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: FutureBuilder<Widget>(
            future: _getInitialScreen(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: buildSpinKitFadingCircle(),
                );
              } else if (snapshot.hasData) {
                return snapshot.data!;
              } else {
                return Scaffold(
                  body: LoginScreen(),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}