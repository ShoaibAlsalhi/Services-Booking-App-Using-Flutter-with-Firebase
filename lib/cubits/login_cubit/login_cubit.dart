import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../layout/customer_layout.dart';
import '../../layout/provider_layout.dart';
import '../../models/user_model/user_model.dart';
import '../../modules/account_blocked_screen/account_blocked_screen.dart';
import '../../modules/admin/admin_screen.dart';
import '../../shared/components/components.dart';
import 'login_states.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginInitial());

  static LoginCubit get(context)=>BlocProvider.of(context);
  UserModel? currentUser;

  /// Login method
  Future<void> login(String email, String password, BuildContext context) async {
    emit(const LoginLoading());
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final userId = userCredential.user!.uid;

      // Fetch user data after login
      fetchUserData(userId, context);

      // Setup FCM and store the token
      await setupFCM(userId);
    } on FirebaseAuthException catch (e) {
      final errorMessage = _mapFirebaseAuthError(e);
      emit(LoginError());
      showToastService(context:context,message: errorMessage,color: Colors.red ,iconData: Icons.error_outline,);
    }
  }
  /// Fetch user data and handle account logic
  void fetchUserData(String userId, BuildContext context) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _handleUserAccountLogic(userId, snapshot.data()!, context);
      } else {
        emit(LoginError());
        showToastService(context:context,message: 'User data not found.',color: Colors.red ,iconData: Icons.error_outline,);
      }
    }, onError: (error) {
      emit(LoginError());
      showToastService(context:context,message: 'Failed to fetch user data:',color: Colors.red ,iconData: Icons.error_outline,);

    });
  }

  /// Handle user account logic
  void _handleUserAccountLogic(
      String userId, Map<String, dynamic> data, BuildContext context) {
    currentUser = UserModel.fromFirestore(userId, data);

    final accountStatus = data['account_status'] ?? true;
    final userRole = data['userRole'] ?? '';

    if (!accountStatus) {
      emit(LoginError());
      showToastService(context:context,message: 'Your account is blocked.',color: Colors.red ,iconData: Icons.error_outline,);
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AccountBlockedScreen()
        ),
      );

      return;
    }

    switch (userRole) {
      case 'customer':
        emit(LoginError());
        replacementNavigateTo(context, const CustomerLayout());
        break;
      case 'service_provider':
        emit(LoginError());
        replacementNavigateTo(context, ProviderLayout(providerId: userId,));
        break;
      case 'admin':
        emit(LoginError());
        replacementNavigateTo(context, const AdminDashboardScreen());
        break;
      default:
        emit(LoginError());
        showToastService(context:context,message: 'Unknown user role. Please contact support.',color: Colors.orange ,iconData: Icons.warning_amber_rounded,);

    }
  }

  /// Map FirebaseAuthException to user-friendly messages
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return  'لا يوجد اتصال بالنرنت يرجاء الاتصال بالنترنت والمحاولة مرة اخرى';
      case 'invalid-credential':
        return ' يرجى التأكد من صحة البريد الالكتروني وكلمة المرور ';
      case 'wrong-password':
        return 'Invalid password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }






  /// Password visibility logic
  bool isPasswordVisible = true;
  IconData suffix = Icons.visibility_off;
  void changePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    suffix = isPasswordVisible ? Icons.visibility_off : Icons.visibility;
    emit( PasswordVisibleState());
  }



  bool isLast =false;
  void chnageIsLast(bool value)
  {
    isLast = value;
    emit(isLastState());
  }


  Future<void> resetPassword(String email, BuildContext context) async {
    if (email.isEmpty) {
      emit(ResetPasswordError(resetPasswordError: 'يرجاء إدخال حساب البريد الالكتروني من أجل إعادة تعين كلمة السر'));
      return;
    }

    emit(LoginLoading());

    try {
      bool isInternetConnected = await _isInternetConnected();
      if (!isInternetConnected) {
        throw FirebaseAuthException(
          code: 'network-request-failed',
          message: 'لايوجد اتصال بالنرنت يرجاء الاتصال بالنترنت والمحاولة مرة اخرى',
        );
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email,);

      emit(ResetPasswordSuccess());
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'حدث خطأ أثناء إعادة تعيين كلمة المرور';
      if (e.code == 'network-request-failed') {
        errorMessage = 'لايوجد اتصال بالنرنت يرجاء الاتصال بالنترنت والمحاولة مرة اخرى';
      }
      emit(ResetPasswordError(resetPasswordError: errorMessage));
    } catch (e) {
      emit(ResetPasswordError(resetPasswordError: 'حدث خطأ أثناء إعادة تعيين كلمة المرور'));
    }
  }

  Future<bool> _isInternetConnected() async {
    // Implement your internet connectivity check here
    return true; // Placeholder
  }


  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> setupFCM(String userId) async {
    emit(FCMSetupLoading()); // Emit loading state

    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? userToken = await _firebaseMessaging.getToken();
        print("FCM Token: $userToken");

        // Save the FCM token to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': userToken,
        });

        emit(FCMSetupSuccess(userToken)); // Emit success state with token
      } else {
        print("User denied FCM permissions");
        emit(FCMSetupError("User denied FCM permissions"));
      }
    } catch (error) {
      print("FCM Token Error $error");
      emit(FCMSetupError(error.toString())); // Emit error state
    }
  }
}
