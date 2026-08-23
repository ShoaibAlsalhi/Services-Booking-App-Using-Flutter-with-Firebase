abstract class ServiceProviderState {
  const ServiceProviderState();
}

class ServiceProviderInitial extends ServiceProviderState {}

class ServiceProviderLoading extends ServiceProviderState {}



class ServiceProviderActionSuccess extends ServiceProviderState {
  final String message;

  const ServiceProviderActionSuccess({required this.message});
}

class ServiceProviderError extends ServiceProviderState {
  final String message;

  const ServiceProviderError({required this.message});
}
