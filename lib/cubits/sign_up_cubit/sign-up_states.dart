abstract class SignUpState {
  const SignUpState();
}

class SignUpInitial extends SignUpState {
  const SignUpInitial();
}

class SignUpLoading extends SignUpState {
  const SignUpLoading();
}

class SignUpSuccess extends SignUpState {
  final String email;

  const SignUpSuccess({required this.email});
}

class SignUpError extends SignUpState {
  final String errorMessage;

  const SignUpError({required this.errorMessage});
}

class SignUpValidationError extends SignUpState {
  final String? emailError;
  final String? passwordError;
  final String? nameError;
  final String? phoneError;

  const SignUpValidationError({this.emailError, this.passwordError, this.nameError, this.phoneError});
}

class SignUpValid extends SignUpState {
  const SignUpValid();
}

class PasswordVisibleState extends SignUpState {
  const PasswordVisibleState();
}
