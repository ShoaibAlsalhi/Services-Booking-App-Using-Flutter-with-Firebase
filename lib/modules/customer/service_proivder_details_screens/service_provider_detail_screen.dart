import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:service_booking_app/modules/customer/service_proivder_details_screens/view_provider_ratings_screen.dart';
import 'package:service_booking_app/shared/styles/colors.dart';


import '../../../models/service_provider/service_provider_model.dart';
import '../../../shared/components/classes.dart';
import '../../../shared/components/components.dart';
import '../get_provider_location_screen/get_provider_location_screen.dart';
import 'customer_view_provider_availability_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Import animations package

class ServiceProviderDetailsScreen extends StatelessWidget {
  final String serviceName;
  final String serviceId;
  final ServiceProviderModel serviceProvider;

  const ServiceProviderDetailsScreen({
    Key? key,
    required this.serviceProvider,
    required this.serviceName,
    required this.serviceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Find the price of the specific service
    var service = serviceProvider.servicesProviderOver.firstWhere(
          (service) => service['serviceId'] == serviceId,
    );

    String serviceDepositPrice = service['serviceDepositPrice'].toString();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        appBar: AppBar(
          title: const Text('بيانات مقدم الخدمة'),
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
          backgroundColor: Colors.white,
          elevation: 2,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: AnimationLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 500),
                childAnimationBuilder: (widget) => SlideAnimation(
                  horizontalOffset: 50.0, // Slide from the right
                  child: FadeInAnimation(
                    child: widget,
                  ),
                ),
                children: [
                  _buildProviderName(serviceProvider.providerName),
                  InkWell(
                    onTap: () => launchPhoneCall(serviceProvider.providerPhoneNumber),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.red[50],
                          child: Icon(Icons.phone_android, size: 20, color: Colors.deepOrange),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          serviceProvider.providerPhoneNumber,
                          style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.red[50],
                        child: Icon(Icons.miscellaneous_services_outlined, size: 20, color: Colors.deepOrange),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        serviceName,
                        style: TextStyle(fontSize: 17),
                      ),
                    ],
                  ),
                  Text(
                    ' عربون مقدم لحجز الخدمة : $serviceDepositPrice',
                    style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ExpandableDescription(description: serviceProvider.description),
                  ),
                  if (serviceProvider.latitude != null && serviceProvider.longitude != null) ...[
                    _buildLocationButton(context),
                    _buildRatingsButton(context),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: _buildAvailabilityButton(context, serviceDepositPrice),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('الخدمات المقدمة'),
                  _buildServicesList(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Location Button
  Widget _buildLocationButton(BuildContext context) {
    return buildCustomButton(
      label: 'موقع مزود الخدمة',
      icon: Icons.location_on,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderLocationScreen(
              providerLatitude: serviceProvider.latitude,
              providerLongitude: serviceProvider.longitude,
              providerName: serviceProvider.providerName,
            ),
          ),
        );
      },
      iconColor: Colors.blueAccent,
      textColor: Colors.blueAccent,
      circleAvatarbackgroundColor: Colors.blue[50]!,
    );
  }

  // Ratings Button
  Widget _buildRatingsButton(BuildContext context) {
    return buildCustomButton(
      label: 'عرض تعليقات المستخدمين',
      icon: Icons.star,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderRatingsScreen(providerId: serviceProvider.id),
          ),
        );
      },
      iconColor: Colors.deepOrange,
      textColor: Colors.deepOrange,
      circleAvatarbackgroundColor: Colors.red[50]!,
    );
  }

  // Services List
  Widget _buildServicesList(BuildContext context) {
    var services = serviceProvider.servicesProviderOver;
    if (services.isEmpty) {
      return const Text('لم يتم العثور على خدمات لهذا المزود.');
    }

    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth < 600) ? 2 : (screenWidth < 900) ? 3 : 4;

    return AnimationLimiter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 500),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0, // Slide from the right
              child: FadeInAnimation(
                child: widget,
              ),
            ),
            children: List.generate(services.length, (index) {
              var service = services[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: _buildServiceCard(service, screenWidth, crossAxisCount),
              );
            }),
          ),
        ),
      ),
    );
  }

  // Service Card
  Widget _buildServiceCard(service, double screenWidth, int crossAxisCount) {
    return AnimationConfiguration.staggeredList(
      position: crossAxisCount,
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0, // Slide from the bottom
        child: FadeInAnimation(
          child: ScaleAnimation(
            scale: 0.5, // Scale up from 50% to 100%
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  width: 190,
                  height: 250,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.red[50],
                        child: const Icon(
                          Icons.miscellaneous_services,
                          color: Colors.deepOrange,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        service['serviceName'].split(' ').join('\n'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'عربون الحجز: ${double.parse(service['serviceDepositPrice'].toString()).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Availability Button
  Widget _buildAvailabilityButton(BuildContext context, serviceDepositPrice) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderAvailabilityScreen(
              serviceProvider: serviceProvider,
              serviceName: serviceName,
              serviceDepositPrice: serviceDepositPrice,
            ),
          ),
        );
      },
      child: const Text(' أحجز الآن '),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.orange[900], // Set the text color
      ),
    );
  }

  // Section Title
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
    );
  }

  // Provider Name
  Widget _buildProviderName(String providerName) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.red[50],
          child: Icon(Icons.person, size: 24, color: Colors.deepOrange),
        ),
        const SizedBox(width: 8),
        Text(
          providerName,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // Custom Button Widget
  Widget buildCustomButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color iconColor,
    required Color textColor,
    required Color circleAvatarbackgroundColor,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: CircleAvatar(
        backgroundColor: circleAvatarbackgroundColor,
        child: Icon(icon, color: iconColor),
      ),
      label: Text(label, style: TextStyle(fontSize: 16, color: textColor)),
    );
  }
}