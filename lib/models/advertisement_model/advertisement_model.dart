import 'package:cloud_firestore/cloud_firestore.dart';

class AdvertisementModel {
  final String id;
  final String imageUrl;
  final String title;
  final String description;

  AdvertisementModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
  });

  factory AdvertisementModel.fromMap(Map<String, dynamic> map, String id) {
    return AdvertisementModel(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
    );
  }
}


/////////////////////////////////////////



class AdvertisementRepository {
  final CollectionReference _adsRef =
  FirebaseFirestore.instance.collection('advertisements');

  Future<List<AdvertisementModel>> fetchAdvertisements() async {
    final querySnapshot = await _adsRef.orderBy('createdAt', descending: true).get();

    return querySnapshot.docs.map((doc) {
      return AdvertisementModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }
}

