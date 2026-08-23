import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:service_booking_app/cubits/sign_up_cubit/sign-up_states.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit() : super(const SignUpInitial());

  // Clear specific field errors
  void clearNameError() {
    if (state is SignUpValidationError) {
      final validationState = state as SignUpValidationError;
      emit(SignUpValidationError(
        nameError: null,
        emailError: validationState.emailError,
        passwordError: validationState.passwordError,
        phoneError: validationState.phoneError,
      ));
    }
  }

  void clearEmailError() {
    if (state is SignUpValidationError) {
      final validationState = state as SignUpValidationError;
      emit(SignUpValidationError(
        nameError: validationState.nameError,
        emailError: null,
        passwordError: validationState.passwordError,
        phoneError: validationState.phoneError,
      ));
    }
  }

  void clearPasswordError() {
    if (state is SignUpValidationError) {
      final validationState = state as SignUpValidationError;
      emit(SignUpValidationError(
        nameError: validationState.nameError,
        emailError: validationState.emailError,
        passwordError: null,
        phoneError: validationState.phoneError,
      ));
    }
  }

  void clearPhoneError() {
    if (state is SignUpValidationError) {
      final validationState = state as SignUpValidationError;
      emit(SignUpValidationError(
        nameError: validationState.nameError,
        emailError: validationState.emailError,
        passwordError: validationState.passwordError,
        phoneError: null,
      ));
    }
  }

  // Validate form fields
  void validateForm(String name, String email, String password, String phone) {
    String? nameError;
    String? emailError;
    String? passwordError;
    String? phoneError;

    if (name.isEmpty) {
      nameError = 'الاسم متطلب.';
    }

    if (email.isEmpty) {
      emailError = 'البريد الالكتروني متطلب';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      emailError = 'Please enter a valid email address.';
    }

    if (password.isEmpty) {
      passwordError = 'كلمة السر متطلبة.';
    } else if (password.length < 6) {
      passwordError = 'كلمة السر يجب ان تحتوي على رموز ارقام على الاقل.';
    }

    if (phone.isEmpty) {
      phoneError = 'رقم الهاتف متطلب.';
    }
    // else if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(phone))
    else if (!RegExp('[0-9]').hasMatch(phone))
    {
      phoneError = 'قم بإدخال رقم صحيح.';
    }

    if (nameError == null &&
        emailError == null &&
        passwordError == null &&
        phoneError == null) {
      emit(const SignUpValid());
    } else {
      emit(SignUpValidationError(
        nameError: nameError,
        emailError: emailError,
        passwordError: passwordError,
        phoneError: phoneError,
      ));
    }
  }

  Future<void> signUp(
      String name, String email, String password, String phone) async {
    validateForm(name, email, password, phone);

    if (state is SignUpValidationError) return;

    emit(const SignUpLoading());

    try {
      // Create user in Firebase Authentication
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user ID
      String userId = userCredential.user!.uid;

      // Store user details in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'id':userId,
        'name': name,
        'email': email,
        'phone': phone,
        'userRole': 'customer', // Default role
        'account_status':true //
      });

      emit(SignUpSuccess(email: email));
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred.';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email is already in use.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address.';
      }
      emit(SignUpError(errorMessage: errorMessage));
    } on FirebaseException catch (e) {
      emit(SignUpError(errorMessage: 'Failed to save user data: ${e.message}'));
    }
  }

  // Password visibility logic
  bool isPasswordVisible = true;
  IconData suffix = Icons.visibility_off;
  void changePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    suffix = isPasswordVisible ? Icons.visibility_off : Icons.visibility;
    emit(const PasswordVisibleState());
  }
}
