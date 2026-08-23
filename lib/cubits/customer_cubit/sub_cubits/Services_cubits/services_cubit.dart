import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:service_booking_app/cubits/customer_cubit/sub_cubits/Services_cubits/services_state.dart';

import '../../../../models/services_models.dart';


import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../models/services_models.dart'; // Import the ServiceModel

class ServiceCubit extends Cubit<ServiceState> {
  ServiceCubit() : super(ServiceInitial());

  static ServiceCubit get(context) => BlocProvider.of(context);

  List<ServiceModel>? services; // Store services here
  StreamSubscription<QuerySnapshot>? _servicesSubscription; // Subscription for real-time updates

  // Fetch services in real-time
  void fetchServicesByCategoryRealTime(String? categoryId) {
    emit(ServiceLoading());

    // Cancel any existing subscription
    _servicesSubscription?.cancel();

    // Listen to the Firestore collection for real-time updates
    if (categoryId != null) {
      _servicesSubscription = FirebaseFirestore.instance
          .collection('services')
          .where('categoryId', isEqualTo: categoryId)
          .snapshots()
          .listen((snapshot) {
        _handleSnapshot(snapshot);
      }, onError: (error) {
        emit(ServiceError('Failed to fetch services: $error'));
      });
    } else {
      _servicesSubscription = FirebaseFirestore.instance
          .collection('services')
          .snapshots()
          .listen((snapshot) {
        _handleSnapshot(snapshot);
      }, onError: (error) {
        emit(ServiceError('Failed to fetch services: $error'));
      });
    }
  }

  // Handle Firestore snapshot data
  void _handleSnapshot(QuerySnapshot snapshot) {
    services = snapshot.docs
        .map((doc) => ServiceModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    if (services!.isEmpty) {
      emit(ServiceCategoryEmpty());
    } else {
      emit(ServiceLoaded()); // Emit a state indicating data is loaded
    }
  }

  // Cancel the subscription when the cubit is closed
  @override
  Future<void> close() {
    _servicesSubscription?.cancel(); // Cancel the subscription to avoid memory leaks
    return super.close();
  }
}