// import 'package:bloc/bloc.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../models/service_provider/service_provider_model.dart';
// import '../../models/services_models.dart';
//
// part 'customer_state.dart';
//
// class CustomerCubit extends Cubit<CustomerState> {
//   CustomerCubit() : super(CustomerInitial());
//   static CustomerCubit get(context) => BlocProvider.of(context);
//
//   // Cache for services and providers to avoid redundant Firestore reads
//   List<ServiceModel>? servicesModel;
//   List<ServiceCategory>? serviceCategory;
//   Map<String, List<ServiceProviderModel>> _cachedProviders = {};
//
//   // Fetch all services
//   Future<void> fetchAllServices() async {
//     emit(CustomerLoading());
//     try {
//       // Use cached data if available
//       if (servicesModel != null) {
//         emit(CustomerServicesLoaded(servicesModel!));
//         return;
//       }
//
//       final snapshot = await FirebaseFirestore.instance.collection('services').get();
//       final services = snapshot.docs
//           .map((doc) => ServiceModel.fromFirestore(doc.id, doc.data()))
//           .toList();
//
//       servicesModel = services; // Cache the services
//       emit(CustomerServicesLoaded(services));
//     } catch (e) {
//       emit(CustomerError('Failed to load services: $e'));
//     }
//   }
//
//   // Fetch all service providers who offer a specific service
//   Future<void> fetchServiceProvidersForService(String serviceId) async {
//     emit(CustomerLoading());
//     try {
//       // Use cached data if available
//       if (_cachedProviders.containsKey(serviceId)) {
//         emit(CustomerServiceProvidersLoaded(_cachedProviders[serviceId]!));
//         return;
//       }
//
//       // Fetch all documents from service_provider_services collection
//       final providersSnapshot = await FirebaseFirestore.instance
//           .collection('service_provider_services')
//           .get();
//
//       // Filter provider IDs that offer the requested service
//       final providerIds = providersSnapshot.docs
//           .where((doc) => (List<Map<String, dynamic>>.from(doc.data()?['services'] ?? []))
//           .any((service) => service['serviceId'] == serviceId))
//           .map((doc) => doc.id)
//           .toList();
//
//       // Fetch all provider details in parallel
//       final providerDetails = await Future.wait(providerIds.map((providerId) async {
//         final userSnapshot = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(providerId)
//             .get();
//         final descriptionSnapshot = await FirebaseFirestore.instance
//             .collection('service_providers')
//             .doc(providerId)
//             .get();
//
//         // Get the services offered by this provider
//         final services = List<Map<String, dynamic>>.from(providersSnapshot.docs
//             .firstWhere((doc) => doc.id == providerId)
//             .data()?['services'] ?? []);
//
//         // Fetch service details from the services array in service_provider_services
//         final servicesProviderOver = await Future.wait(services.map((service) async {
//           final serviceId = service['serviceId'];
//           final serviceDepositPrice = service['depositPrice'] ?? 'Deposit Price not available';
//
//           // Fetch the service name from the services collection
//           final serviceDoc = await FirebaseFirestore.instance
//               .collection('services')
//               .doc(serviceId)
//               .get();
//
//           final serviceName = serviceDoc.exists
//               ? (serviceDoc.data() != null && serviceDoc.data()!.containsKey('name')
//               ? serviceDoc.data()!['name']
//               : 'Service name not available')
//               : 'Service not found';
//
//           return {
//             'serviceId': serviceId,
//             'serviceName': serviceName,
//             'serviceDepositPrice': serviceDepositPrice,
//           };
//         }).toList());
//
//         final averageRating = await _fetchAverageRating(providerId);
//
//         return ServiceProviderModel(
//           id: providerId,
//           name: userSnapshot.data()?['name'] ?? 'Unknown Provider',
//           providerPhoneNumber: userSnapshot.data()?['phone'] ?? 'Unknown Provider',
//           userRole: userSnapshot.data()?['userRole'] ?? 'Unknown Provider',
//           description: descriptionSnapshot.data()?['description'] ?? 'No Description',
//           services: services,
//           servicesProviderOver: servicesProviderOver,
//           providerName: userSnapshot.data()?['name'] ?? 'Unknown Provider',
//           imageUrl: userSnapshot.data()?['imageUrl'] ?? 'null',
//           rating: averageRating,
//           availability: descriptionSnapshot.data()?['availability'] ?? {},
//           latitude: userSnapshot.data()?['latitude'] ?? 'null',
//           longitude: userSnapshot.data()?['longitude'] ?? 'null',
//         );
//       }));
//
//       _cachedProviders[serviceId] = providerDetails; // Cache the providers
//       emit(CustomerServiceProvidersLoaded(providerDetails));
//     } catch (e) {
//       emit(CustomerError('Failed to load service providers: $e'));
//       print('Error fetching providers: $e');
//     }
//   }
//   // Helper method to fetch the average rating for a provider
//   Future<double> _fetchAverageRating(String providerId) async {
//     try {
//       final ratingsSnapshot = await FirebaseFirestore.instance
//           .collection('service_providers')
//           .doc(providerId)
//           .collection('ratings')
//           .get();
//
//       if (ratingsSnapshot.docs.isEmpty) {
//         return 0.0; // No ratings available
//       }
//
//       final totalRating = ratingsSnapshot.docs
//           .map((doc) => doc['rating'] as double)
//           .reduce((a, b) => a + b);
//
//       return totalRating / ratingsSnapshot.docs.length;
//     } catch (e) {
//       print("Error fetching ratings: $e");
//       return 0.0; // Return 0.0 if there's an error
//     }
//   }
//
//   // Fetch services for a specific category
//   Future<void> fetchServicesByCategory(String? categoryId) async {
//     emit(CustomerLoading());
//     try {
//       QuerySnapshot snapshot;
//       if (categoryId != null) {
//         snapshot = await FirebaseFirestore.instance
//             .collection('services')
//             .where('categoryId', isEqualTo: categoryId)
//             .get();
//       } else {
//         snapshot = await FirebaseFirestore.instance.collection('services').get();
//       }
//
//       final services = snapshot.docs
//           .map((doc) => ServiceModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
//           .toList();
//
//       if (services.isEmpty) {
//         emit(CustomerCategoryServicesisEmpty());
//       } else {
//         emit(CustomerServicesLoaded(services));
//       }
//     } catch (e) {
//       emit(CustomerError('Failed to fetch services: $e'));
//     }
//   }
//
//
//
//
//   // Fetch all service categories
//   Future<void> fetchCategories() async {
//     emit(CustomerLoading());
//     try {
//       final snapshot = await FirebaseFirestore.instance.collection('categories').get();
//
//       // Create a list of ServiceCategory objects from Firestore data
//       final categories = snapshot.docs.map((doc) {
//         return ServiceCategory.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
//       }).toList();
//       serviceCategory=categories;
//
//       if (categories.isEmpty) {
//         emit(CustomerCategoriesEmpty());
//       } else {
//         emit(CustomerCategoriesLoaded(categories));
//       }
//     } catch (e) {
//       emit(CustomerError('Failed to fetch categories: $e'));
//     }
//   }
// // Fetch all service categories
//
//
// }