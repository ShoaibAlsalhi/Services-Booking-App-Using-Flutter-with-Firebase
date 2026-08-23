import 'package:bloc/bloc.dart';
import 'package:service_booking_app/cubits/user_profile_cubit/user_profile_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model/user_model.dart';


class UserProfileCubit extends Cubit<UserProfileState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // FirebaseFirestore instance directly

  UserProfileCubit() : super(UserProfileInitial());

  // Method to fetch user profile by userId
  Future<void> fetchUserProfile(String userId) async {
    try {
      emit(UserProfileLoading());

      // Fetching user data from Firestore
      DocumentSnapshot docSnapshot = await _firestore.collection('users').doc(userId).get();

      if (docSnapshot.exists) {
        UserModel user = UserModel.fromFirestore(docSnapshot.id, docSnapshot.data() as Map<String, dynamic>);
        emit(UserProfileLoaded(user));
      } else {
        emit(UserProfileError("User not found"));
      }
    } catch (e) {
      emit(UserProfileError("Failed to load user data"));
    }
  }

  // Method to update user profile
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      emit(UserProfileLoading());

      // Updating user data in Firestore
      await _firestore.collection('users').doc(updatedUser.id).update({
        'name': updatedUser.name,
        'email': updatedUser.email,
        'phone': updatedUser.phone,
        'account_status': updatedUser.account_status,
      });

      // On success, emit the updated user
      emit(UserProfileUpdated(updatedUser));
    } catch (e) {
      emit(UserProfileError("Failed to update user data"));
    }
  }
}
