
import '../../models/user_model/user_model.dart';

abstract class UserProfileState  {
  const UserProfileState();

  @override
  List<Object?> get props => [];
}

class UserProfileInitial extends UserProfileState {}

class UserProfileLoading extends UserProfileState {}

class UserProfileLoaded extends UserProfileState {
  final UserModel user;

  const UserProfileLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class UserProfileUpdated extends UserProfileState {
  final UserModel updatedUser;

  const UserProfileUpdated(this.updatedUser);

  @override
  List<Object?> get props => [updatedUser];
}

class UserProfileError extends UserProfileState {
  final String message;

  const UserProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
