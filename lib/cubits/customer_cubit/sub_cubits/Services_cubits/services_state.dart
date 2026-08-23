
abstract class ServiceState {}

class ServiceInitial extends ServiceState {}

class ServiceLoading extends ServiceState {}

class ServiceLoaded extends ServiceState {} // No data passed here

class ServiceCategoryEmpty extends ServiceState {}

class ServiceError extends ServiceState {
  final String message;
  ServiceError(this.message);
}