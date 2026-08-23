import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class RequestState {}

class RequestInitial extends RequestState {}

class RequestLoading extends RequestState {}

class RequestSuccess extends RequestState {}

class RequestError extends RequestState {
  final String errorMessage;
  RequestError({required this.errorMessage});
}

class RequestExists extends RequestState {
  final String status;
  RequestExists({required this.status});
}

class RequestNotExist extends RequestState {}

class RequestUpdated extends RequestState {
  final String status;
  RequestUpdated({required this.status});
}




//////////////////////////////////////////


class RequestCubit extends Cubit<RequestState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RequestCubit() : super(RequestInitial());

  // Check if the user has already submitted a request
  Future<void> checkIfRequestExists(String customerId) async {
    try {
      final requestDoc = await _firestore
          .collection('upgradeRequests')
          .doc(customerId)
          .get();

      if (requestDoc.exists) {
        final status = requestDoc['status'] ?? 'New'; // Get current request status
        emit(RequestExists(status: status)); // Emit state with current status
      } else {
        emit(RequestNotExist());
      }
    } catch (e) {
      emit(RequestError(errorMessage: 'Failed to fetch request status.'));
    }
  }

  // Send upgrade request to Firestore
  Future<void> sendUpgradeRequest(String customerId, String message) async {
    emit(RequestLoading());
    try {
      await _firestore.collection('upgradeRequests').doc(customerId).set({
        'userId': customerId,
        'requestMessage': message,
        'status': 'New', // Set status to 'Pending' initially
        'timestamp': FieldValue.serverTimestamp(),
      });

      emit(RequestSuccess());
    } catch (e) {
      emit(RequestError(errorMessage: 'Failed to send upgrade request.'));
    }
  }

  // Fetch and update the request status from Firestore (admin approves or rejects)
  Future<void> updateRequestStatus(String customerId, String status) async {
    try {
      await _firestore.collection('upgradeRequests').doc(customerId).update({
        'status': status,
      });
      emit(RequestUpdated(status: status));
    } catch (e) {
      emit(RequestError(errorMessage: 'Failed to update request status.'));
    }
  }
}
