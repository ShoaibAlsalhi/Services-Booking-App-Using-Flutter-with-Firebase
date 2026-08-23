
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProviderModel {
  final String id;
  final String name; // Provider's name (from 'users' collection)
  final String providerPhoneNumber;
  final String userRole;
  final String description; // Add description to the model
  final List<Map<dynamic, dynamic>> services;
  final List<Map<dynamic, dynamic>> servicesProviderOver;
  final Map<String, dynamic> availability;
  final String providerName; // Add providerName field to store the name of the service provider
  final String? imageUrl; // Add imageUrl field to store the provider's profile image
  final double rating; // Add rating field to store the average rating
  final double latitude;
  final double longitude;

  ServiceProviderModel({
    required this.id,
    required this.name,
    required this.providerPhoneNumber,
    required this.userRole,
    required this.description,
    required this.services,
    required this.servicesProviderOver,
    required this.availability,
    required this.providerName,
    this.imageUrl, // Initialize the imageUrl
    this.rating = 0.0,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  // Factory method to create the model from Firestore data
  factory ServiceProviderModel.fromFirestore(String id, Map<String, dynamic> data) {
    final services = List<Map<String, dynamic>>.from(data['services'] ?? []);
    final servicesProviderOver = List<Map<String, dynamic>>.from(data['services'] ?? []);

    return ServiceProviderModel(
      id: id,
      name: data['name'] ?? 'Unknown Provider', // Default to 'Unknown Provider' if no name is found
      providerPhoneNumber: data['phone'] ?? 'Unknown Provider',
      userRole: data['userRole'] ?? 'Unknown Provider',
      description: data['description'] ?? 'No Description', // Default description if not available
      services: services,
      servicesProviderOver: servicesProviderOver,
      availability: {},
      providerName: data['providerName'] ?? 'Unknown Service Provider', // Get the providerName from the data
      imageUrl: data['imageUrl']??'null', // Get the imageUrl from the data
      rating: data['rating'] ?? 0.0,
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
    );
  }

}