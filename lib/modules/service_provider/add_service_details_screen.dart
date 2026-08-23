import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:service_booking_app/shared/styles/colors.dart';

import '../../cubits/service_provider_cubit/service_provider_cubit.dart';
import '../../models/services_models.dart';
import '../../shared/components/components.dart';



class AddServiceDetailsScreen extends StatelessWidget {
  final ServiceModel service;
  final String providerId;
  final ServiceProviderCubit cubit;

  const AddServiceDetailsScreen({
    Key? key,
    required this.service,
    required this.providerId,
    required this.cubit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final depositPriceController = TextEditingController();
    final descriptionController = TextEditingController();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        appBar: AppBar(
          title: Text('إضافة  ${service.name}'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إضافة العربون والوصف',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              buildTextFormField(
                controller: depositPriceController,
                labelText: '  عربون مقدم ماقبل العمل ',
                iconData: Icons.price_change,
                keyboardType: TextInputType.number,
                // errorText: emailError,
              ),
              const SizedBox(height: 20),
              buildTextFormField(
                controller: descriptionController,
                maxLines: 3,
                labelText: 'وصف الخدمة',
                iconData: Icons.description,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: buildElevatedButton(
                  onPressed: () {
                    final depositPrice = double.tryParse(depositPriceController.text);
                    final description = descriptionController.text;

                    if (depositPrice == null || depositPrice <= 0) {
                      showToastService(
                        context: context,
                        message: 'العربون  متطلوب.',
                        color: Colors.red,
                        iconData: Icons.error_outline,
                      );
                      return;
                    }

                    if (description.isEmpty) {
                      showToastService(
                        context: context,
                        message: 'وصف الخدمة متطلوب.',
                        color: Colors.red,
                        iconData: Icons.error_outline,
                      );
                      return;
                    }

                    // Use the cubit to add the service
                    cubit.addServiceToProvider(
                      providerId,
                      ServiceModel(
                        id: service.id,
                        name: service.name,
                        description: description,
                        depositPrice: depositPrice,
                        categoryId: service.categoryId, // Include the categoryId
                      ),
                    );

                    Navigator.pop(context);

                    showToastService(
                      context: context,
                      message: 'تم إضافة الخدمة بنجاح!',
                      color: Colors.green,
                      iconData: Icons.check,
                    );
                  },
                  child: const Text(
                    'إضافة الخدمة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}