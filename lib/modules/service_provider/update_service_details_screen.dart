import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/service_provider_cubit/service_provider_cubit.dart';
import '../../models/services_models.dart';
import '../../shared/components/components.dart';
import '../../shared/styles/colors.dart';

class UpdateServiceDetailsScreen extends StatelessWidget {
  final ServiceModel service;
  final String providerId;

  const UpdateServiceDetailsScreen({
    Key? key,
    required this.service,
    required this.providerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final depositPriceController = TextEditingController(text: service.depositPrice.toString());
    final descriptionController = TextEditingController(text: service.description);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        appBar: AppBar(
          title: Text('تعديل بيانات  ${service.name}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Show confirmation dialog
                _showDeleteConfirmationDialog(context);
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تعديل بيانات الخدمة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              buildTextFormField(
                controller: depositPriceController,
                labelText: 'عربون الخدمة الجديد',
                iconData: Icons.price_change,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              buildTextFormField(
                controller: descriptionController,
                maxLines: 3,
                labelText: 'وصف الخدمة ',
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
                        message: 'سعر الخدمة متطلب.',
                        color: Colors.red,
                        iconData: Icons.error,
                      );
                      return;
                    }
      
                    if (description.isEmpty) {
                      showToastService(
                        context: context,
                        message: 'وصف الخدمة متطلب.',
                        color: Colors.red,
                        iconData: Icons.error,
                      );
                      return;
                    }
      
                    // Update the service details in Firestore
                    context.read<ServiceProviderCubit>().updateProviderService(
                      providerId,
                      service.id,
                      depositPrice,
                      description,
                    );
      
                    Navigator.pop(context);
      
                    showToastService(
                      context: context,
                      message: 'تم تعديل بيانات الخدمة بنجاح!',
                      color: Colors.green,
                      iconData: Icons.check,
                    );
                  },
                  child: const Text(
                    'تعديل ',
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

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف الخدمة'),
            content: const Text('سيتم حذف الخدمة هل تريد حذفها بالفعل؟!!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Cancel button
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  // Perform delete operation
                  context.read<ServiceProviderCubit>().deleteProviderService(
                    providerId,
                    service.id,
                  );
          
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close update screen
          
                  showToastService(
                    context: context,
                    message: 'تم حذف الخدمة بنجاح!',
                    color: Colors.green,
                    iconData: Icons.check,
                  );
                },
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }
}
