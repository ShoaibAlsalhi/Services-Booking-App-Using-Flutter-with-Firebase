import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../cubits/customer_cubit/sub_cubits/Services_cubits/services_cubit.dart';
import '../../cubits/customer_cubit/sub_cubits/Services_cubits/services_state.dart';
import '../../models/services_models.dart'; // Import the ServiceModel
import '../../shared/components/classes.dart';
import '../../shared/components/components.dart';
import '../../shared/styles/colors.dart';
import 'list_service_providers_screen.dart';

class CustomerListServicesScreen extends StatefulWidget {
  final String? categoryId; // Accept categoryId as a parameter
  final String? categoryName;

  const CustomerListServicesScreen({Key? key, this.categoryId, this.categoryName}) : super(key: key);

  @override
  _CustomerListServicesScreenState createState() =>
      _CustomerListServicesScreenState();
}

class _CustomerListServicesScreenState extends State<CustomerListServicesScreen> {
  late ServiceCubit serviceCubit;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    serviceCubit = ServiceCubit()
      ..fetchServicesByCategoryRealTime(widget.categoryId); // Initialize and fetch services
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => serviceCubit,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: defaultBackgroundColor,
          appBar: AppBar(
            title:  Text(widget.categoryName.toString()),
            actions: [
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.red[50],
                  child: const Icon(Icons.search, color: Colors.red),
                ),
                onPressed: () {
                  // Get the current list of services from the cubit
                  final services = serviceCubit.services;
                  if (services != null) {
                    showSearch(
                      context: context,
                      delegate: ServicesSearchDelegate(services: services),
                    );
                  }
                },
              ),
            ],
          ),
          body: BlocConsumer<ServiceCubit, ServiceState>(
            listener: (context, state) {
              if (state is ServiceError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              final serviceCubit = ServiceCubit.get(context); // Access the cubit instance

              if (state is ServiceLoading) {
                return buildSpinKitFadingCircle(); // Show loading spinner
              } else if (state is ServiceLoaded) {
                final services = serviceCubit.services; // Access services from the cubit
                if (services == null || services.isEmpty) {
                  return Center(
                    child: Text(
                      'No services found.',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }
                return _buildServicesList(services); // Show the list of services
              } else if (state is ServiceError) {
                return Center(
                  child: Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                );
              } else if (state is ServiceCategoryEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ' لم يتم العثور على خدمات لهذه الفئة ',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const Center(child: Text('No services available.'));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildServicesList(List<ServiceModel> services) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceProviderListScreen(
                            serviceId: service.id,
                            serviceName: service.name,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.red[50],
                            child: const Icon(
                              Icons.miscellaneous_services,
                              color: Colors.deepOrange,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'تفاصيل الخدمة',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor: Colors.red[50],
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.deepOrange,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}