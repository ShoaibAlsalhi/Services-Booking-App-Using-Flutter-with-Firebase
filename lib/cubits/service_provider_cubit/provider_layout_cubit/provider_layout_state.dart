abstract class ProviderLayoutStates {}


class ProviderLayoutInitialState extends ProviderLayoutStates{}

class ChangeProviderBottomNavigationBarState extends ProviderLayoutStates{}

class UnseenBookingsCountUpdated extends ProviderLayoutStates{}


class FcmLoading extends ProviderLayoutStates {}

class FcmPermissionDenied extends ProviderLayoutStates {}

class FcmTokenReceived extends ProviderLayoutStates {
  final String token;

  FcmTokenReceived({required this.token});
}
class FcmError extends ProviderLayoutStates {
  final String error;

  FcmError({required this.error});
}

class FcmMessageReceived extends ProviderLayoutStates {
  final String title;
  final String body;
  FcmMessageReceived({required this.title, required this.body});
}

class FcmMessageOpened extends ProviderLayoutStates {
  final String title;
  final String body;
  FcmMessageOpened({required this.title, required this.body});
}