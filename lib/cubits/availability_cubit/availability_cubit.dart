import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'availability_state.dart';

class AvailabilityCubit extends Cubit<AvailabilityState> {
  final String providerId;
  StreamSubscription<DocumentSnapshot>? _availabilitySubscription;

  AvailabilityCubit({required this.providerId}) : super(AvailabilityInitial());

  // Start listening to real-time updates
  void listenToAvailability() {
    emit(AvailabilityLoading());

    _availabilitySubscription = FirebaseFirestore.instance
        .collection('service_providers')
        .doc(providerId)
        .snapshots()
        .listen(
          (snapshot) {
        if (snapshot.exists) {
          final availability = snapshot.data()?['availability'] ?? {};
          emit(AvailabilityLoaded(availability: Map<String, dynamic>.from(availability)));
        } else {
          emit(AvailabilityLoaded(availability: {}));
        }
      },
      onError: (error) {
        emit(AvailabilityError(message: 'Failed to fetch availability: $error'));
      },
    );
  }

  // Save or update availability for a specific day
  Future<void> saveDayAvailability(String day, String startTime, String endTime, bool isDayOff) async {
    if (day.isEmpty || startTime.isEmpty || endTime.isEmpty) {
      emit(AvailabilityError(message: 'All fields are required.'));
      return;
    }

    emit(AvailabilitySaving());
    try {
      final availabilityRef = FirebaseFirestore.instance
          .collection('service_providers')
          .doc(providerId);

      await availabilityRef.set({
        'availability': {
          day: {
            'startTime': startTime,
            'endTime': endTime,
            'dayIsOff': isDayOff, // Save the dayIsOff status
          },
        },
      }, SetOptions(merge: true)); // Merge to preserve other days

      emit(AvailabilitySuccess(message: 'Availability for $day updated successfully.'));
    } catch (e) {
      emit(AvailabilityError(message: 'Failed to update availability: $e'));
    }
  }

  // Update the dayIsOff status for a specific day
  Future<void> updateDayOffStatus(String day, bool isDayOff) async {
    emit(AvailabilityLoading());

    try {
      final availabilityRef = FirebaseFirestore.instance
          .collection('service_providers')
          .doc(providerId);

      // Update the dayIsOff status without changing other fields
      await availabilityRef.update({
        'availability.$day.dayIsOff': isDayOff, // Only update the 'dayIsOff' field
      });

      emit(AvailabilitySuccess(message: '$day day off status updated successfully.'));
    } catch (e) {
      emit(AvailabilityError(message: 'Failed to update $day day off status: $e'));
    }
  }

  // Cancel the subscription when no longer needed
  @override
  Future<void> close() {
    _availabilitySubscription?.cancel();
    return super.close();
  }
}
