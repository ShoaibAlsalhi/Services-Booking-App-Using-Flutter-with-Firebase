// booking_state.dart

import '../../../models/booking_model/booking_model.dart';

abstract class ProviderBookingState {}

class BookingLoading extends ProviderBookingState {}
class BookingWaiting extends ProviderBookingState {}

class BookingLoaded extends ProviderBookingState {
  final List<BookingModel> bookings;

  BookingLoaded(this.bookings);
}

class BookingError extends ProviderBookingState {
  final String errorMessage;

  BookingError(this.errorMessage);
}

