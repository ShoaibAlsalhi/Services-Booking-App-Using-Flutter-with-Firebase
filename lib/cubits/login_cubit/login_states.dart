abstract class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  const LoginSuccess();
}

class LoginError extends LoginState {


  const LoginError();
}

class LoginValidationError extends LoginState {
  final String? emailError;
  final String? passwordError;

  const LoginValidationError({this.emailError, this.passwordError});
}

class LoginValid extends LoginState {
  const LoginValid();
}

class LoginPasswordVisibilityChanged extends LoginState {}

class PasswordVisibleState extends LoginState {}

class isLastState extends LoginState {}

class ResetPasswordError extends LoginState {
  String resetPasswordError;
  ResetPasswordError({required this.resetPasswordError});
}

class ResetPasswordSuccess extends LoginState {
  ResetPasswordSuccess();
}


class FCMSetupLoading extends LoginState {}

class FCMSetupSuccess extends LoginState {
  final String? token;
  FCMSetupSuccess(this.token);
}

class FCMSetupError extends LoginState {
  final String error;
  FCMSetupError(this.error);
}