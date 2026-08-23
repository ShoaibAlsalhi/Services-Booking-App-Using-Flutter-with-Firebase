import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../models/services_models.dart'; // Import the ServiceCategory model
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit() : super(CategoryInitial());

  static CategoryCubit get(context) => BlocProvider.of(context);

  List<ServiceCategory> categories = []; // Store categories here
  StreamSubscription<QuerySnapshot>? _categoriesSubscription; // Subscription for real-time updates

  // Fetch categories in real-time
  void fetchCategoriesRealTime() {
    emit(CategoryLoading());

    // Listen to the Firestore collection for real-time updates
    _categoriesSubscription = FirebaseFirestore.instance
        .collection('categories')
        .snapshots()
        .listen((snapshot) {
      // Map Firestore documents to ServiceCategory objects
      categories = snapshot.docs.map((doc) {
        return ServiceCategory.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      if (categories!.isEmpty) {
        emit(CategoryEmpty());
      } else {
        emit(CategoryLoaded()); // Emit a state indicating data is loaded
      }
    }, onError: (error) {
      emit(CategoryError('Failed to fetch categories: $error'));
    });
  }

  // Cancel the subscription when the cubit is closed
  @override
  Future<void> close() {
    _categoriesSubscription?.cancel(); // Cancel the subscription to avoid memory leaks
    return super.close();
  }
}