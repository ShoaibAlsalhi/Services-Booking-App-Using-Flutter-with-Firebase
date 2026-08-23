import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../models/services_models.dart';
import '../../modules/admin/service_management_screen.dart';
import '../../modules/customer/customer_list_services_screen.dart';
import '../../modules/customer/list_service_providers_screen.dart';
import '../styles/colors.dart';
import 'components.dart';

class ExpandableDescription extends StatefulWidget {
  final String description;

  const ExpandableDescription({Key? key, required this.description}) : super(key: key);

  @override
  _ExpandableDescriptionState createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    const int maxLength = 100;
    bool isLongDescription = widget.description.length > maxLength;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isExpanded
                ? widget.description
                : (isLongDescription ? widget.description.substring(0, maxLength) + '...' : widget.description),
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          if (isLongDescription)
            TextButton(
              onPressed: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Text(
                isExpanded ? ' قراءة أقل' : ' قراءة المزيد ',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }
}



//search category class

class CategoriesSearchDelegate extends SearchDelegate {
  final List<dynamic> categories;
  final bool fromAdminScreen;

  CategoriesSearchDelegate({
    required this.categories,
    this.fromAdminScreen = false,
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
      icon: const Icon(Icons.arrow_forward), // Adjusted for RTL
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final trimmedQuery = query.trim();
    final filteredCategories = categories
        .where((category) =>
        category.name.toLowerCase().contains(trimmedQuery.toLowerCase()))
        .toList();

    if (filteredCategories.isEmpty) {
      return const Center(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'لم يتم العثور على فئة مطابقة.', // Translated message
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.builder(
        itemCount: filteredCategories.length,
        itemBuilder: (context, index) {
          final category = filteredCategories[index];
          return ListTile(
            title: Text(category.name),
            // subtitle: Text(category.description),
            onTap: () {
              if (!fromAdminScreen) {
                navigateTo(
                  context,
                  CustomerListServicesScreen(categoryId: category.id),
                );
              } else {
                navigateTo(
                  context,
                  ServiceManagementScreen(categoryId: category.id),
                );
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final trimmedQuery = query.trim();
    final suggestions = categories
        .where((category) =>
        category.name.toLowerCase().contains(trimmedQuery.toLowerCase()))
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final category = suggestions[index];
          return ListTile(
            title: Text(category.name),
            // subtitle: Text(category.description),
            onTap: () {
              query = category.name;
              if (!fromAdminScreen) {
                navigateTo(
                  context,
                  CustomerListServicesScreen(categoryId: category.id),
                );
              } else {
                navigateTo(
                  context,
                  ServiceManagementScreen(categoryId: category.id),
                );
              }
            },
          );
        },
      ),
    );
  }
}


//search services class


class ServicesSearchDelegate extends SearchDelegate {
  final List<ServiceModel> services;
  final bool fromAdminScreen;

  ServicesSearchDelegate({
    required this.services,
    this.fromAdminScreen = false,
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
      icon: const Icon(Icons.arrow_forward), // Adjusted for RTL
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final trimmedQuery = query.trim();
    final filteredServices = services
        .where((service) =>
        service.name.toLowerCase().contains(trimmedQuery.toLowerCase()))
        .toList();

    if (filteredServices.isEmpty) {
      return const Center(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'لم يتم العثور على خدمات مطابقة.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.builder(
        itemCount: filteredServices.length,
        itemBuilder: (context, index) {
          final service = filteredServices[index];
          return ListTile(
            title: Text(service.name),
            subtitle: Text(service.description),
            trailing: Text('${service.depositPrice.toStringAsFixed(2)} \$'),
            onTap: () {
              if (fromAdminScreen) {
                navigateTo(
                  context,
                  EditServiceScreen(service: service),
                );
              }
              else {
                navigateTo(
                  context,
                  ServiceProviderListScreen(
                    serviceId: service.id,
                    serviceName: service.name,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final trimmedQuery = query.trim();
    final suggestions = services
        .where((service) =>
        service.name.toLowerCase().contains(trimmedQuery.toLowerCase()))
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final service = suggestions[index];
          return ListTile(
            title: Text(service.name),
            // subtitle: Text(service.description),
            onTap: () {
              query = service.name;
              if (fromAdminScreen) {
                navigateTo(
                  context,
                  EditServiceScreen(service: service),
                );
              }
              else {
                navigateTo(
                  context,
                  ServiceProviderListScreen(
                    serviceId: service.id,
                    serviceName: service.name,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
