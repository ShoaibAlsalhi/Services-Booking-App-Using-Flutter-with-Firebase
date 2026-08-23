import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:service_booking_app/cubits/service_provider_cubit/service_provider_states.dart';
import '../../models/services_models.dart';

class ServiceProviderCubit extends Cubit<ServiceProviderState> {
  ServiceProviderCubit() : super(ServiceProviderInitial());

  // Fetch all available services, optionally filtered by category
  Stream<List<ServiceModel>> fetchAvailableServices(String providerId, {String? categoryId}) {
    return FirebaseFirestore.instance.collection('services').snapshots().asyncMap((snapshot) async {
      // Fetch services already linked to the provider
      final providerServicesSnapshot = await FirebaseFirestore.instance
          .collection('service_provider_services')
          .doc(providerId)
          .get();

      final providerServices = providerServicesSnapshot.exists
          ? List<Map<String, dynamic>>.from(providerServicesSnapshot.data()?['services'] ?? [])
          : [];

      final providerServiceIds = providerServices.map((service) => service['serviceId']).toList();

      // Filter the services to show only the ones not added by the provider
      return snapshot.docs
          .where((doc) => !providerServiceIds.contains(doc.id))
          .map((doc) => ServiceModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .where((service) => categoryId == null || service.categoryId == categoryId) // Filter by category
          .toList();
    });
  }

  // Fetch services linked to a specific service provider
  Stream<List<ServiceModel>> fetchProviderServices(String providerId) async* {
    final providerDoc = FirebaseFirestore.instance
        .collection('service_provider_services')
        .doc(providerId)
        .snapshots();

    await for (final snapshot in providerDoc) {
      if (snapshot.exists) {
        final providerServices = List<Map<String, dynamic>>.from(
          snapshot.data()?['services'] ?? [],
        );

        // Fetch all global services for linking
        final allServicesSnapshot = await FirebaseFirestore.instance
            .collection('services')
            .get();

        final allServices = allServicesSnapshot.docs
            .map((doc) => ServiceModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
            .toList();

        // Link provider-specific data with global services
        final linkedServices = providerServices.map((providerService) {
          final globalService = allServices.firstWhere(
                (service) => service.id == providerService['serviceId'],
            orElse: () => ServiceModel(
              id: providerService['serviceId'],
              name: 'Unknown Service',
              description: '',
              depositPrice: 0.0,
              categoryId: '', // Default category ID
            ),
          );

          return ServiceModel(
            id: globalService.id,
            name: globalService.name,
            description: providerService['description'], // Use provider-specific description
            depositPrice: providerService['depositPrice'], // Use provider-specific price
            categoryId: globalService.categoryId, // Include category ID
          );
        }).toList();

        yield linkedServices;
      } else {
        yield [];
      }
    }
  }

  // Add service to a service provider's list
  Future<void> addServiceToProvider(String providerId, ServiceModel service) async {
    try {
      final providerDoc = FirebaseFirestore.instance
          .collection('service_provider_services')
          .doc(providerId);

      final snapshot = await providerDoc.get();

      if (snapshot.exists) {
        // Append new serviceId to the existing list
        await providerDoc.update({
          'services': FieldValue.arrayUnion([
            {
              'serviceId': service.id,
              'depositPrice': service.depositPrice, // Provider-specific price
              'description': service.description, // Provider-specific description
              'categoryId': service.categoryId, // Include category ID
            }
          ]),
        });
      } else {
        // Create a new document with the service
        await providerDoc.set({
          'services': [
            {
              'serviceId': service.id,
              'depositPrice': service.depositPrice, // Provider-specific price
              'description': service.description, // Provider-specific description
              'categoryId': service.categoryId, // Include category ID
            }
          ],
        });
      }

      emit(ServiceProviderActionSuccess(message: 'Service added successfully.'));
    } catch (e) {
      emit(ServiceProviderError(message: 'Failed to add service: $e'));
    }
  }

  // Update the Provider Service
  Future<void> updateProviderService(
      String providerId,
      String serviceId,
      double depositPrice,
      String description,
      ) async {
    try {
      final providerDoc = FirebaseFirestore.instance
          .collection('service_provider_services')
          .doc(providerId);

      final snapshot = await providerDoc.get();

      if (snapshot.exists) {
        final services = List<Map<String, dynamic>>.from(snapshot.data()?['services'] ?? []);

        // Find and update the service in the list
        final updatedServices = services.map((service) {
          if (service['serviceId'] == serviceId) {
            return {
              ...service,
              'depositPrice': depositPrice,
              'description': description,
              'categoryId': service['categoryId'], // Preserve category ID
            };
          }
          return service;
        }).toList();

        // Save the updated list back to Firestore
        await providerDoc.update({'services': updatedServices});
        emit(ServiceProviderActionSuccess(message: 'Service updated successfully.'));
      }
    } catch (e) {
      emit(ServiceProviderError(message: 'Failed to update service: $e'));
    }
  }

  // Delete the Provider Service
  Future<void> deleteProviderService(String providerId, String serviceId) async {
    try {
      final providerDoc = FirebaseFirestore.instance
          .collection('service_provider_services')
          .doc(providerId);

      final snapshot = await providerDoc.get();

      if (snapshot.exists) {
        final services = List<Map<String, dynamic>>.from(snapshot.data()?['services'] ?? []);

        // Remove the service with the given serviceId
        final updatedServices =
        services.where((service) => service['serviceId'] != serviceId).toList();

        // Update Firestore
        await providerDoc.update({'services': updatedServices});

        emit(ServiceProviderActionSuccess(message: 'Service deleted successfully.'));
      }
    } catch (e) {
      emit(ServiceProviderError(message: 'Failed to delete service: $e'));
    }
  }
}