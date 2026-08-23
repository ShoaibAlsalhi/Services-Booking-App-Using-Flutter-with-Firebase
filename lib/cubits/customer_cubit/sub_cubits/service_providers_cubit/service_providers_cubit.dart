

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:service_booking_app/cubits/customer_cubit/sub_cubits/service_providers_cubit/service_providers_state.dart';

import '../../../../models/service_provider/service_provider_model.dart';


import 'dart:async';



class CustomerServiceProviderCubit extends Cubit<CustomerServiceProviderState> {
  CustomerServiceProviderCubit() : super(CustomerServiceProviderInitial());

  static CustomerServiceProviderCubit get(context) => BlocProvider.of(context);

  List<ServiceProviderModel>? providers; // Store providers here
  String searchQuery = ''; // Store search query
  int crossAxisCount = 2; // Store grid column count
  StreamSubscription<QuerySnapshot>? _serviceProviderSubscription; // Subscription for real-time updates

  // Fetch service providers in real-time
  void fetchServiceProvidersForService(String serviceId) {
    emit(CustomerServiceProviderLoading());

    // Cancel any existing subscription
    _serviceProviderSubscription?.cancel();

    // Listen to the Firestore collection for real-time updates
    _serviceProviderSubscription = FirebaseFirestore.instance
        .collection('service_provider_services')
        .snapshots()
        .listen((providersSnapshot) async {
      // Filter provider IDs that offer the requested service
      final providerIds = providersSnapshot.docs
          .where((doc) => (List<Map<String, dynamic>>.from(doc.data()?['services'] ?? []))
          .any((service) => service['serviceId'] == serviceId))
          .map((doc) => doc.id)
          .toList();

      // Fetch all provider details in parallel
      final providerDetails = await Future.wait(providerIds.map((providerId) async {
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(providerId)
            .get();
        final descriptionSnapshot = await FirebaseFirestore.instance
            .collection('service_providers')
            .doc(providerId)
            .get();

        // Get the services offered by this provider
        final services = List<Map<String, dynamic>>.from(providersSnapshot.docs
            .firstWhere((doc) => doc.id == providerId)
            .data()?['services'] ?? []);

        // Fetch service details from the services array in service_provider_services
        final servicesProviderOver = await Future.wait(services.map((service) async {
          final serviceId = service['serviceId'];
          final serviceDepositPrice = service['depositPrice'] ?? 'Deposit Price not available';

          // Fetch the service name from the services collection
          final serviceDoc = await FirebaseFirestore.instance
              .collection('services')
              .doc(serviceId)
              .get();

          final serviceName = serviceDoc.exists
              ? (serviceDoc.data() != null && serviceDoc.data()!.containsKey('name')
              ? serviceDoc.data()!['name']
              : 'Service name not available')
              : 'Service not found';

          return {
            'serviceId': serviceId,
            'serviceName': serviceName,
            'serviceDepositPrice': serviceDepositPrice,
          };
        }).toList());

        final averageRating = await _fetchAverageRating(providerId);

        return ServiceProviderModel(
          id: providerId,
          name: userSnapshot.data()?['name'] ?? 'Unknown Provider',
          providerPhoneNumber: userSnapshot.data()?['phone'] ?? 'Unknown Provider',
          userRole: userSnapshot.data()?['userRole'] ?? 'Unknown Provider',
          description: descriptionSnapshot.data()?['description'] ?? 'No Description',
          services: services,
          servicesProviderOver: servicesProviderOver,
          providerName: userSnapshot.data()?['name'] ?? 'Unknown Provider',
          imageUrl: userSnapshot.data()?['imageUrl'] ?? 'null',
          rating: averageRating,
          availability: descriptionSnapshot.data()?['availability'] ?? {},
          latitude: userSnapshot.data()?['latitude'] ?? 'null',
          longitude: userSnapshot.data()?['longitude'] ?? 'null',
        );
      }));

      providers = providerDetails; // Cache the providers
      emit(CustomerServiceProviderLoaded()); // Emit a state indicating data is loaded
    }, onError: (error) {
      emit(CustomerServiceProviderError('Failed to load service providers: $error'));
    });
  }

  // Update search query
  void updateSearchQuery(String query) {
    searchQuery = query;
    emit(CustomerServiceProviderLoaded()); // Re-emit the state to trigger UI update
  }

  // Toggle grid column count
  void toggleCrossAxisCount() {
    crossAxisCount = crossAxisCount == 2 ? 1 : 2;
    emit(CustomerServiceProviderLoaded()); // Re-emit the state to trigger UI update
  }

  // Helper method to fetch the average rating for a provider
  Future<double> _fetchAverageRating(String providerId) async {
    try {
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(providerId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        return 0.0; // No ratings available
      }

      final totalRating = ratingsSnapshot.docs
          .map((doc) => doc['rating'] as double)
          .reduce((a, b) => a + b);

      return totalRating / ratingsSnapshot.docs.length;
    } catch (e) {
      print("Error fetching ratings: $e");
      return 0.0; // Return 0.0 if there's an error
    }
  }

  // Cancel the subscription when the cubit is closed
  @override
  Future<void> close() {
    _serviceProviderSubscription?.cancel(); // Cancel the subscription to avoid memory leaks
    return super.close();
  }
}