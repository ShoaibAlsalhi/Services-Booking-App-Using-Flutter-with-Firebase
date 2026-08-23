// States
abstract class BookingConfirmationState {}

class BookingInitialState extends BookingConfirmationState {}

class BookingTimeUpdatedState extends BookingConfirmationState {}

class PaymentImageUpdatedState extends BookingConfirmationState {}

class BookingLoadingState extends BookingConfirmationState {}

class BookingSuccessState extends BookingConfirmationState {}

class BookingErrorState extends BookingConfirmationState {
  final String message;
  BookingErrorState(this.message);
}
class BookingLoadedState extends BookingConfirmationState {
  BookingLoadedState();
}
class ChangePaymentMethodState extends BookingConfirmationState {
  ChangePaymentMethodState();
}



