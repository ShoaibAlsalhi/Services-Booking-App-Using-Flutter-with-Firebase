import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:service_booking_app/modules/customer/service_proivder_details_screens/service_provider_detail_screen.dart';

import '../../cubits/customer_cubit/sub_cubits/service_providers_cubit/service_providers_cubit.dart';
import '../../cubits/customer_cubit/sub_cubits/service_providers_cubit/service_providers_state.dart';
import '../../models/service_provider/service_provider_model.dart'; // Import the ServiceProviderModel
import '../../shared/components/components.dart';
import '../../shared/styles/colors.dart';
class ServiceProviderListScreen extends StatelessWidget {
  final String serviceId;
  final String serviceName;

  const ServiceProviderListScreen({
    Key? key,
    required this.serviceId,
    required this.serviceName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CustomerServiceProviderCubit()
        ..fetchServiceProvidersForService(serviceId), // Initialize and fetch providers
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: defaultBackgroundColor,
          appBar: AppBar(
            title: Text('مقدمي خدمة $serviceName'),
            elevation: 0,
            leading: IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.red[50],
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.red,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            actions: [
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.red[50],
                  child: const Icon(
                    Icons.search,
                    color: Colors.red,
                  ),
                ),
                onPressed: () {
                  final cubit = CustomerServiceProviderCubit.get(context);
                  showSearch(
                    context: context,
                    delegate: ProviderSearchDelegate(
                      providers: cubit.providers ?? [],
                      serviceName: serviceName,
                      serviceId: serviceId,
                    ),
                  );
                },
              ),
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.red[50],
                  child: BlocBuilder<CustomerServiceProviderCubit, CustomerServiceProviderState>(
                    builder: (context, state) {
                      final cubit = CustomerServiceProviderCubit.get(context);
                      return Icon(
                        cubit.crossAxisCount == 2 ? Icons.view_list : Icons.grid_view,
                        color: Colors.red,
                      );
                    },
                  ),
                ),
                onPressed: () {
                  final cubit = CustomerServiceProviderCubit.get(context);
                  cubit.toggleCrossAxisCount(); // Toggle grid column count
                },
              ),
            ],
          ),
          body: BlocBuilder<CustomerServiceProviderCubit, CustomerServiceProviderState>(
            builder: (context, state) {
              final cubit = CustomerServiceProviderCubit.get(context);

              if (state is CustomerServiceProviderLoading) {
                return buildSpinKitFadingCircle(); // Show loading spinner
              } else if (state is CustomerServiceProviderLoaded) {
                final providers = cubit.providers ?? [];
                final filteredProviders = cubit.searchQuery.isEmpty
                    ? providers
                    : providers
                    .where((provider) => provider.name
                    .toLowerCase()
                    .contains(cubit.searchQuery.toLowerCase()))
                    .toList();

                return _buildServiceProviderGrid(filteredProviders, context, cubit.crossAxisCount);
              } else if (state is CustomerServiceProviderError) {
                return Center(
                  child: Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              return const Center(child: Text('No providers available.'));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildServiceProviderGrid(
      List<ServiceProviderModel> providers, BuildContext context, int crossAxisCount) {
    // Filter providers by userRole
    final filteredProviders = providers
        .where((provider) => provider.userRole == 'service_provider')
        .toList();

    // If no providers are found, display a "Not Found" message
    if (filteredProviders.isEmpty) {
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
              ' لم يتم إضافة مقدمي خدمات لهذة الخدمة ',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Build the grid if providers are found
    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: crossAxisCount == 2 ? 0.8 : 1.5,
        ),
        itemCount: filteredProviders.length,
        itemBuilder: (context, index) {
          final provider = filteredProviders[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 500),
            columnCount: crossAxisCount,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceProviderDetailsScreen(
                        serviceProvider: provider,
                        serviceName: serviceName,
                        serviceId: serviceId,
                      ),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (provider.imageUrl != null)
                            buildeCachedNetworkImage(
                              url: provider.imageUrl!,
                              borderRadius: 10,
                              fit: BoxFit.cover,
                            ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      provider.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10.0),
                                      bottomRight: Radius.circular(10.0),
                                    ),
                                  ),
                                  child: Text(
                                    provider.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
}/////////////////////////////////////////////////

class ProviderSearchDelegate extends SearchDelegate {
  final List<ServiceProviderModel> providers;
  final String serviceName;
  final String serviceId;

  ProviderSearchDelegate({
    required this.providers,
    required this.serviceName,
    required this.serviceId,
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final trimmedQuery = query.trim();
    final filteredProviders = providers
        .where((provider) =>
    provider.userRole == 'service_provider' &&
        (provider.name.toLowerCase().contains(trimmedQuery.toLowerCase()) ||
            provider.providerPhoneNumber.contains(trimmedQuery)))
        .toList();

    if (filteredProviders.isEmpty) {
      return const Center(
        child: Text(
          'لم يتم العثور على مزودين مطابقين.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredProviders.length,
      itemBuilder: (context, index) {
        final provider = filteredProviders[index];
        return ListTile(
          title: Text(provider.name),
          subtitle: Text(' رقم الهاتف : ${provider.providerPhoneNumber}'),
          onTap: () {
            close(context, provider);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final trimmedQuery = query.trim();
    final suggestions = providers
        .where((provider) =>
    provider.userRole == 'service_provider' &&
        (provider.name.toLowerCase().contains(trimmedQuery.toLowerCase()) ||
            provider.providerPhoneNumber.contains(trimmedQuery)))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final provider = suggestions[index];
        return ListTile(
          title: Text(provider.name),
          subtitle: Text(' رقم الهاتف : ${provider.providerPhoneNumber}'),
          onTap: () {
            query = provider.name;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceProviderDetailsScreen(
                  serviceProvider: provider,
                  serviceName: serviceName,
                  serviceId: serviceId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}