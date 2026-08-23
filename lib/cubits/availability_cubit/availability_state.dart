part of 'availability_cubit.dart';

abstract class AvailabilityState {
  const AvailabilityState();
}

class AvailabilityInitial extends AvailabilityState {}

class AvailabilityLoading extends AvailabilityState {}

class AvailabilityLoaded extends AvailabilityState {
  final Map<String, dynamic> availability;

  const AvailabilityLoaded({required this.availability});
}

class AvailabilitySaving extends AvailabilityState {}

class AvailabilitySuccess extends AvailabilityState {
  final String message;

  const AvailabilitySuccess({required this.message});
}

class AvailabilityError extends AvailabilityState {
  final String message;

  const AvailabilityError({required this.message});
}

class AvailabilityDaySelected extends AvailabilityState {
  final String day;

  const AvailabilityDaySelected({required this.day});
}

class AvailabilityTimeUpdated extends AvailabilityState {
  final String startTime;
  final String endTime;

  const AvailabilityTimeUpdated({required this.startTime, required this.endTime});
}
