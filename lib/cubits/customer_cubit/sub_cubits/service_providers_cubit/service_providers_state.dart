
abstract class CustomerServiceProviderState {}

class CustomerServiceProviderInitial extends CustomerServiceProviderState {}

class CustomerServiceProviderLoading extends CustomerServiceProviderState {}

class CustomerServiceProviderLoaded extends CustomerServiceProviderState {} // No data passed here

class CustomerServiceProviderError extends CustomerServiceProviderState {
  final String message;
  CustomerServiceProviderError(this.message);
}