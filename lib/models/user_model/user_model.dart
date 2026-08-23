class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String userRole;
  final bool account_status;
  final String? location; // Optional
  final double? latitude; // Optional
  final double? longitude; // Optional
  final String? imageUrl;
  final String? fcmToken; // Add this field
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userRole,
    required this.account_status,
    this.location,
    this.latitude,
    this.longitude,
    this.imageUrl, // Ensure this field exists
    this.fcmToken,
  });

  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      userRole: data['userRole'] ?? '',
      account_status: data['account_status'] ?? false,
      location: data['location'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      imageUrl: data['imageUrl']??'', // Ensure this field is mapped
      fcmToken: data['fcmToken'], // Add this line
    );
  }
}
