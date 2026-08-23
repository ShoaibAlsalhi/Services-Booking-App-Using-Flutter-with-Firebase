import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_booking_app/shared/styles/colors.dart';

import '../../models/user_model/user_model.dart';


import '../../shared/components/classes.dart';
import '../../shared/components/components.dart';


import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Import animations package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserProfileScreen extends StatelessWidget {
  UserProfileScreen({super.key});
  final userId = FirebaseAuth.instance.currentUser?.uid ?? "";

  Stream<DocumentSnapshot<Map<String, dynamic>>> _fetchUserFromFirestore(String userId) {
    return FirebaseFirestore.instance.collection('users').doc(userId).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _fetchDescriptionForServiceProvider(String userId) {
    return FirebaseFirestore.instance.collection('service_providers').doc(userId).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _fetchUserFromFirestore(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return buildSpinKitFadingCircle();
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.red,
                  ),
                ),
              );
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  'User not found.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              );
            } else {
              final userData = snapshot.data!;
              final user = UserModel.fromFirestore(userId, userData.data()!);

              return SingleChildScrollView(
                child: AnimationLimiter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 500),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0, // Slide from the bottom
                        child: FadeInAnimation(
                          child: widget,
                        ),
                      ),
                      children: [
                        const SizedBox(height: 20),
                        // Stack for Profile Picture and Edit Icon
                        Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            // Profile Picture
                            buildeCachedNetworkImage(url: user.imageUrl.toString(),
                              width: 150,
                              height: 150,
                              borderRadius: 100,
                               fit: BoxFit.cover
                            ),
                            // Edit Icon
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditUserProfileScreen(user: user),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // User Name
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // User Details with Icons
                        _buildUserDetail(Icons.email, user.email),
                        const SizedBox(height: 10),
                        _buildUserDetail(Icons.phone, user.phone),
                        const SizedBox(height: 10),
                        _buildUserDetail(Icons.person, "Role: ${user.userRole}"),
                        const SizedBox(height: 10),
                        if (user.userRole == 'service_provider') ...[
                          const SizedBox(height: 20),
                          // Description for Service Providers
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: _fetchDescriptionForServiceProvider(userId),
                            builder: (context, descriptionSnapshot) {
                              if (descriptionSnapshot.connectionState == ConnectionState.waiting) {
                                return buildSpinKitFadingCircle();
                              } else if (descriptionSnapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error: ${descriptionSnapshot.error}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                );
                              } else if (!descriptionSnapshot.hasData || !descriptionSnapshot.data!.exists) {
                                return const Center(
                                  child: Text(
                                    '  لا يتوفر وصف ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              } else {
                                final description = descriptionSnapshot.data!.data()?['description'] ?? 'لا يتوفر وصف.';
                                return Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    Text(
                                      " الوصف: ",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ExpandableDescription(description: description),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                        if (user.latitude != null && user.longitude != null) ...[
                          const SizedBox(height: 20),
                          // Display Map
                          Container(
                            height: 200, // Set the height of the map
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(user.latitude!, user.longitude!),
                                  zoom: 14,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId("user_location"),
                                    position: LatLng(user.latitude!, user.longitude!),
                                    infoWindow: InfoWindow(title: user.name),
                                  ),
                                },
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                        // Logout Button
                        ElevatedButton.icon(
                          onPressed: () {
                            showLogoutConfirmationDialog(context);
                          },
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            "تسجيل خروج",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // Helper method to build user details with icons
  Widget _buildUserDetail(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.green[50],
            child: Icon(
              icon,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}//////////////////////////////////////////////////










class EditUserProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditUserProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditUserProfileScreenState createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController; // New controller for description
  TextEditingController _locationController = TextEditingController();
  TextEditingController _latitudeController = TextEditingController();
  TextEditingController _longitudeController = TextEditingController();
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;
  late GoogleMapController mapController;

  LatLng _currentLocation = LatLng(0.0, 0.0);
  late Marker _marker;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _descriptionController = TextEditingController(); // Initialize description controller
    _imageUrl = widget.user.imageUrl; // Initialize the image URL from the user model

    if (widget.user.location != null) {
      _locationController.text = widget.user.location!;
    }
    if (widget.user.latitude != null) {
      _latitudeController.text = widget.user.latitude.toString();
      _currentLocation = LatLng(widget.user.latitude!, widget.user.longitude!);
    }
    if (widget.user.longitude != null) {
      _longitudeController.text = widget.user.longitude.toString();
    }

    _marker = Marker(
      markerId: MarkerId('current_location'),
      position: _currentLocation,
    );

    // Fetch the service provider's description if the user is a service provider
    if (widget.user.userRole == 'service_provider') {
      _fetchServiceProviderDescription();
    }
  }

  Future<void> _fetchServiceProviderDescription() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(widget.user.id)
          .get();

      if (doc.exists) {
        setState(() {
          _descriptionController.text = doc['description'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching description: $e');
    }
  }

  Future<void> _updateUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image to Firebase Storage if a new image is selected
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_profile_images/${widget.user.id}.jpg');
        await storageRef.putFile(_imageFile!);
        _imageUrl = await storageRef.getDownloadURL();
      }

      // Update Firestore document with user details
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'latitude': double.tryParse(_latitudeController.text.trim()) ?? 0.0,
        'longitude': double.tryParse(_longitudeController.text.trim()) ?? 0.0,
        'imageUrl': _imageUrl, // Update the image URL in Firestore
      });

      // Update the service provider's description if the user is a service provider
      if (widget.user.userRole == 'service_provider') {
        await FirebaseFirestore.instance
            .collection('service_providers')
            .doc(widget.user.id)
            .update({
          'description': _descriptionController.text.trim(),
        });
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' تم تعديل البيانات بنجاح ')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحديث الملف الشخصي: $e')),
      );
    }
  }

  void _navigateToLocationPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          onLocationSelected: (LatLng selectedLocation, String locationString) {
            setState(() {
              _currentLocation = selectedLocation;
              _latitudeController.text = selectedLocation.latitude.toString();
              _longitudeController.text = selectedLocation.longitude.toString();
              _locationController.text = locationString;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
         backgroundColor: defaultBackgroundColor,
        appBar: AppBar(
          title: const Text(" تعديل الملف الشخصي "),
          backgroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Stack(
            children: [
              if (_isLoading)
                 buildSpinKitFadingCircle(),
              if (!_isLoading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Profile Picture with Camera Icon
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            alignment: Alignment.bottomLeft,
                            children: [
                              // Display the image
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(100), // Adjust to the radius you want
                                  child: _imageFile != null
                                      ? Image.file(
                                    _imageFile!,
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover, // To make the image cover the area
                                  )

                                      : buildeCachedNetworkImage(
                                    url: _imageUrl.toString(),
                                    width: 150,
                                    height: 150,
                                    borderRadius: 100,
                                      fit: BoxFit.cover

                                  )


                              ),

                              // Camera Icon
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent, // Background color of the camera icon
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white, // Border color
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white, // Icon color
                                  size: 20,
                                ),
                              ),
                            ],
                          ),

                        ),
                      ),

                      const SizedBox(height: 20),
                      buildTextFormField(
                        controller: _nameController,
                        labelText: 'تعديل الاسم ',
                        iconData: Icons.person,
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الاسم متطلب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 7),
                      buildTextFormField(
                        controller: _phoneController,
                        labelText: 'تعديل رقم الهاتف ',
                        iconData: Icons.phone_android,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'رقم الهاتف متطلب';
                          }
                          return null;
                        },
                      ),
                      // Show description field only for service providers
                      SizedBox(height: 7,),
                      if (widget.user.userRole == 'service_provider')
                      buildTextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        labelText: 'تعديل الوصف ',
                        iconData: Icons.description,
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الوصف متطلب';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),
                      Container(
                        alignment: Alignment(1, 4),
                        child: TextButton.icon(
                          onPressed: _navigateToLocationPicker,
                          icon: Icon(
                            Icons.location_on, // Use a location icon
                            color: Colors.blueAccent, // Match the text color
                          ),
                          label: const Text(
                            " تحديد الموقع ",
                            style: TextStyle(
                              color: Colors.blueAccent, // Customize the text color
                              fontSize: 16, // Customize the font size
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      buildElevatedButton(
                        width: 200,
                        height: 50,
                        onPressed: () {
                          _updateUserProfile();
                        },
                        child: const Text(
                          '  تعديل البيانات ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
}


//////////////////////////////////////////////






class LocationPickerScreen extends StatefulWidget {
  final Function(LatLng, String) onLocationSelected;

  const LocationPickerScreen({Key? key, required this.onLocationSelected}) : super(key: key);

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GoogleMapController mapController;
  LatLng _currentLocation = LatLng(0.0, 0.0);
  late Marker _marker;
  bool _isLoading = true; // Add a flag for loading state

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission denied')),
      );
      return;
    }

    // Set loading state to true while fetching location
    setState(() {
      _isLoading = true;
    });

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _marker = Marker(
        markerId: MarkerId('current_location'),
        position: _currentLocation,
      );
      _isLoading = false; // Set loading to false after the location is fetched
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(" تحديد الموقع "),
          backgroundColor: defaultBackgroundColor,
        ),
        body: _isLoading
            ?  buildSpinKitFadingCircle() // Show loader when loading
            : Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation,
                zoom: 14,
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              markers: {_marker},
              onCameraMove: (position) {
                // Update the marker position and the coordinates as the map moves
                setState(() {
                  _currentLocation = position.target;
                  _marker = Marker(
                    markerId: MarkerId('current_location'),
                    position: _currentLocation,
                  );
                });
              },
              onTap: (LatLng location) {
                // Handle the tap event to select a new location
                setState(() {
                  _currentLocation = location;
                  _marker = Marker(
                    markerId: MarkerId('current_location'),
                    position: _currentLocation,
                  );
                });
              },
            ),
            // Other UI elements like the floating action button
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Return selected location to the previous screen
            widget.onLocationSelected(_currentLocation, 'Lat: ${_currentLocation.latitude}, Lon: ${_currentLocation.longitude}');
            Navigator.pop(context);
          },
          child: const Icon(Icons.check),
        ),
      ),
    );
  }
}
