import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:service_booking_app/modules/service_provider/update_service_details_screen.dart';

import '../../cubits/service_provider_cubit/service_provider_cubit.dart';
import '../../cubits/service_provider_cubit/service_provider_states.dart';
import '../../models/services_models.dart';
import '../../shared/components/components.dart';
import '../../shared/styles/colors.dart';
import 'add_service_details_screen.dart';

class ServiceProviderScreen extends StatefulWidget {
  const ServiceProviderScreen({Key? key}) : super(key: key);

  @override
  _ServiceProviderScreenState createState() => _ServiceProviderScreenState();
}

class _ServiceProviderScreenState extends State<ServiceProviderScreen> {
  final providerId = FirebaseAuth.instance.currentUser?.uid;
  String? selectedCategoryId; // Track the selected category

  @override
  Widget build(BuildContext context) {
    if (providerId == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: const Scaffold(
          backgroundColor: defaultBackgroundColor,
          body: Center(
            child: Text('No user is logged in. Please log in again.'),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (context) => ServiceProviderCubit(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: defaultBackgroundColor,
          body: BlocConsumer<ServiceProviderCubit, ServiceProviderState>(
            listener: (context, state) {
              if (state is ServiceProviderActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.green),
                );
              } else if (state is ServiceProviderError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
              }
            },
            builder: (context, state) {
              final cubit = context.read<ServiceProviderCubit>();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('خدماتك',
                        style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildProviderServicesList(cubit, providerId!),
                    const SizedBox(height: 20),
                    const Text('خدمات لم تقم بإضافتها',
                        style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    // Category filter buttons
                    _buildCategoryFilterButtons(cubit, providerId!),
                    const SizedBox(height: 10),
                    // Available services list
                    _buildAvailableServicesList(cubit, providerId!),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Build category filter buttons

  Widget _buildCategoryFilterButtons(ServiceProviderCubit cubit, String providerId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fetchCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return  buildSpinKitFadingCircle();
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching categories.'));
        }

        final categories = snapshot.data ?? [];

        // Ensure the selected category is at the beginning of the list
        List<Map<String, dynamic>> orderedCategories = [];
        if (selectedCategoryId != null) {
          // Find the selected category
          final selectedCategory = categories.firstWhere(
                (category) => category['id'] == selectedCategoryId,
            orElse: () => {},
          );

          // Remove the selected category from the list
          orderedCategories = List.from(categories)
            ..removeWhere((category) => category['id'] == selectedCategoryId);

          // Add the selected category at the beginning
          if (selectedCategory.isNotEmpty) {
            orderedCategories.insert(0, selectedCategory);
          }
        } else {
          // If no category is selected, use the original list
          orderedCategories = List.from(categories);
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Button for "All" categories
              _buildCategoryButton(
                label: 'الكل',
                icon: Icons.miscellaneous_services, // Same icon for all buttons
                isSelected: selectedCategoryId == null,
                onPressed: () {
                  setState(() {
                    selectedCategoryId = null; // Clear category filter
                  });
                },
              ),
              // Buttons for each category (with the selected one at the beginning)
              ...orderedCategories.map((category) {
                return _buildCategoryButton(
                  label: category['name'],
                  icon: Icons.miscellaneous_services, // Same icon for all buttons
                  isSelected: selectedCategoryId == category['id'],
                  onPressed: () {
                    setState(() {
                      selectedCategoryId = category['id']; // Set category filter
                    });
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

// Updated _buildCategoryButton to include an icon
  Widget _buildCategoryButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: isSelected ? Colors.white : Colors.deepOrange),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.deepOrange,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.deepOrange : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.deepOrange),
          ),
        ),
      ),
    );
  }






  // Fetch categories from Firestore
  Stream<List<Map<String, dynamic>>> _fetchCategories() {
    return FirebaseFirestore.instance
        .collection('categories')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Add the document ID to the data
      return data;
    }).toList());
  }

  Widget _buildProviderServicesList(ServiceProviderCubit cubit, String providerId) {
    return StreamBuilder<List<ServiceModel>>(
      stream: cubit.fetchProviderServices(providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildSpinKitFadingCircle();
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching your services.'));
        }
        final services = snapshot.data ?? [];
        if (services.isEmpty) {
          return const Text('You have no services linked yet.');
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling
          itemCount: services.length,
          padding: const EdgeInsets.all(8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: _calculateChildAspectRatio(context), // Responsive aspect ratio
          ),
          itemBuilder: (context, index) {
            final service = services[index];

            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 500),
              columnCount: 2,
              child: SlideAnimation(
                verticalOffset: 50.0,
                curve: Curves.linear,
                child: FadeInAnimation(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service Icon

                          const SizedBox(height: 8.0),
                          Text(
                            service.name,
                            style: const TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            service.depositPrice.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          // Display the category name
                          FutureBuilder<String>(
                            future: _fetchCategoryName(service.categoryId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return buildSpinKitFadingCircle();
                              }
                              if (snapshot.hasError) {
                                return const Text('Unknown Category');
                              }
                              return Text(
                                'فئة: ${snapshot.data ?? 'Unknown'}',
                                style: const TextStyle(
                                  // fontSize: 12.0,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                              );
                            },
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.center,
                            child: IconButton(
                              icon: CircleAvatar(
                                backgroundColor: Colors.orange[50],
                                child: const Icon(Icons.edit, color: Colors.orange),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UpdateServiceDetailsScreen(
                                      service: service,
                                      providerId: providerId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvailableServicesList(ServiceProviderCubit cubit, String providerId) {
    return StreamBuilder<List<ServiceModel>>(
      stream: cubit.fetchAvailableServices(providerId, categoryId: selectedCategoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return  buildSpinKitFadingCircle();
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching available services.'));
        }
        final services = snapshot.data ?? [];
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling

          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return InkWell(
              onTap: () {
                final cubit = context.read<ServiceProviderCubit>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddServiceDetailsScreen(
                      service: service,
                      providerId: providerId,
                      cubit: cubit, // Pass the cubit instance
                    ),
                  ),
                );
              },
              child: AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  horizontalOffset: 50,
                  curve: Curves.linear,
                  child: FadeInAnimation(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red[50],
                          child: Icon(
                            Icons.design_services,
                            color: Colors.red[800], // Icon color
                          ),
                        ),
                        title: Text(
                          service.name,
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(service.description),
                            const SizedBox(height: 4),
                            // Display the category name
                            FutureBuilder<String>(
                              future: _fetchCategoryName(service.categoryId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return buildSpinKitFadingCircle();
                                }
                                if (snapshot.hasError) {
                                  return const Text('Unknown Category');
                                }
                                return Text(
                                  'Category: ${snapshot.data ?? 'Unknown'}',
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        trailing: CircleAvatar(
                          backgroundColor: Colors.red[50],
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.red[800],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Fetch category name from Firestore
  Future<String> _fetchCategoryName(String? categoryId) async {
    if (categoryId == null) return 'Unknown';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .get();
      return doc.data()?['name'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Function to calculate responsive aspect ratio
  double _calculateChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adjust the aspect ratio based on screen size
    if (screenWidth < 600) {
      // For smaller screens (e.g., phones)
      return 0.8; // Wider and shorter items
    } else if (screenWidth < 1200) {
      // For medium screens (e.g., tablets)
      return 0.1; // Slightly taller items
    } else {
      // For larger screens (e.g., desktops)
      return 1.0; // Square or taller items
    }
  }
}