class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double depositPrice;
  final String categoryId; // Reference to the service category

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.depositPrice,
    required this.categoryId, // Add this field
  });

  factory ServiceModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ServiceModel(
      id: id,
      name: data['name'] ?? 'Unnamed Service',
      description: data['description'] ?? '',
      depositPrice: (data['depositPrice'] ?? 0).toDouble(),
      categoryId: data['categoryId'] ?? '', // Add this field
    );
  }
}



////////////////////////////


class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final String? imageUrl; // Add this field for the image URL

  ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl, // Include the image URL in the constructor
  });

  // Factory constructor to create a ServiceCategory from Firestore data
  factory ServiceCategory.fromFirestore(String id, Map<String, dynamic> data) {
    return ServiceCategory(
      id: id,
      name: data['name'] ?? 'Unnamed Category',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'], // Add the image URL from Firestore data
    );
  }
}