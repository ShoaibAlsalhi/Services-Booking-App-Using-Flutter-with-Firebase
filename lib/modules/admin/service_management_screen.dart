import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../models/services_models.dart';
import '../../shared/components/classes.dart';
import '../../shared/components/components.dart';
import '../../shared/styles/colors.dart';
import '../customer/list_service_providers_screen.dart';

class ServiceManagementScreen extends StatelessWidget {
  final String? categoryId; // Accept categoryId as a parameter

  const ServiceManagementScreen({Key? key, this.categoryId}) : super(key: key);

  // Fetch services based on categoryId
  Stream<List<ServiceModel>> _getServices() {
    if (categoryId != null) {
      // Fetch services that belong to the selected category
      return FirebaseFirestore.instance
          .collection('services')
          .where('categoryId', isEqualTo: categoryId)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc.id, doc.data()))
          .toList());
    } else {
      // Fetch all services if no categoryId is provided
      return FirebaseFirestore.instance
          .collection('services')
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc.id, doc.data()))
          .toList());
    }
  }

  // Function to show a dialog for adding a service
  void _showAddServiceDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _serviceNameController = TextEditingController();
    final TextEditingController _serviceDescriptionController = TextEditingController();
    final TextEditingController _serviceDepositPriceController = TextEditingController();

    bool isLoading = false; // Loader state

    // Show dialog
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('إضافة خدمة'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _serviceNameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الخدمة',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال اسم الخدمة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _serviceDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'وصف الخدمة',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال وصف الخدمة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _serviceDepositPriceController,
                      decoration: const InputDecoration(
                        labelText: 'سعر الخدمة',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال سعر الخدمة';
                        }
                        if (double.tryParse(value) == null) {
                          return 'يرجى إدخال قيمة صحيحة للسعر';
                        }
                        return null;
                      },
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 16),
                       buildSpinKitFadingCircle(),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() {
                        isLoading = true; // Show loader
                      });
          
                      final String serviceName = _serviceNameController.text;
                      final String serviceDescription = _serviceDescriptionController.text;
                      final double serviceDepositPrice = double.tryParse(_serviceDepositPriceController.text) ?? 0;
          
                      try {
                        await FirebaseFirestore.instance.collection('services').add({
                          'name': serviceName,
                          'description': serviceDescription,
                          'depositPrice': serviceDepositPrice,
                          'categoryId': categoryId, // Include the categoryId
                          'created_at': FieldValue.serverTimestamp(),
                        });
          
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم إضافة الخدمة بنجاح')),
                        );
                        Navigator.pop(context); // Close the dialog
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('حدث خطأ أثناء إضافة الخدمة')),
                        );
                      } finally {
                        setState(() {
                          isLoading = false; // Hide loader
                        });
                      }
                    }
                  },
                  child: const Text('إضافة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<ServiceModel> services=[];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('إدارة الخدمات'),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.red[50],
                child: IconButton(
                  icon: const Icon(Icons.add,color: Colors.red,),
                  onPressed: () => _showAddServiceDialog(context),
                ),
              ),
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.red[50],
                  child: const Icon(Icons.search, color: Colors.red),
                ),
                onPressed: () {
                  // Get the current list of services from the state
                  {
                    showSearch(
                      context: context,
                      delegate: ServicesSearchDelegate(services: services,fromAdminScreen: true),
                    );
                  }
                },
              ),
            ],
          ),
          body: StreamBuilder<List<ServiceModel>>(
            stream: _getServices(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return buildSpinKitFadingCircle();
              }
              if (snapshot.hasError) {
                return const Center(child: Text('حدث خطأ في تحميل الخدمات'));
              }
               services = snapshot.data ?? [];
              if (services.isEmpty) {
                return const Center(child: Text('لا توجد خدمات بعد.'));
              }
              return _buildServicesList(services);
            },
          ),
        ),
      ),


    );
  }
  Widget _buildServicesList(List<ServiceModel> services) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = (constraints.maxWidth / 180).floor();

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 2 / 2.5,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 500),
              columnCount: crossAxisCount,
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditServiceScreen(service: service,),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.deepOrange[50],
                            child: const Icon(
                              Icons.miscellaneous_services,
                              color: Colors.deepOrange,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            service.name.split(' ').join('\n'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 15),
                          CircleAvatar(
                            backgroundColor: Colors.red[50],
                            child: Icon(
                              Icons.edit,
                              color: Colors.red,
                              size: 20,
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
}







/////////////////////////////////////////


///////////////////////////////////////////

// Edit Service Screen




class EditServiceScreen extends StatefulWidget {
  final ServiceModel service;

  const EditServiceScreen({Key? key, required this.service}) : super(key: key);

  @override
  _EditServiceScreenState createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serviceNameController;
  late TextEditingController _serviceDescriptionController;
  late TextEditingController _serviceDepositPriceController;
  late TextEditingController _categoryController;
  bool isLoading = false; // Loader state
  String? selectedCategoryId; // Selected category ID
  List<Map<String, dynamic>> categories = []; // List of categories

  @override
  void initState() {
    super.initState();
    _serviceNameController = TextEditingController(text: widget.service.name);
    _serviceDescriptionController =
        TextEditingController(text: widget.service.description);
    _serviceDepositPriceController =
        TextEditingController(text: widget.service.depositPrice.toString());
    _categoryController = TextEditingController();
    selectedCategoryId = widget.service.categoryId; // Set initial category
    _fetchCategories(); // Fetch categories from Firestore
  }

  // Fetch categories from Firestore
  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();
      setState(() {
        categories = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Add the document ID to the data
          return data;
        }).toList();
      });

      // Set the initial category name in the controller
      if (selectedCategoryId != null) {
        final selectedCategory = categories.firstWhere(
              (category) => category['id'] == selectedCategoryId,
          orElse: () => {'name': ''},
        );
        _categoryController.text = selectedCategory['name'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ في تحميل الفئات')),
      );
    }
  }

  // Function to update the service in Firestore
  Future<void> _updateService() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true; // Show loader
      });

      final String serviceName = _serviceNameController.text;
      final String serviceDescription = _serviceDescriptionController.text;
      final double serviceDepositPrice =
          double.tryParse(_serviceDepositPriceController.text) ?? 0;

      try {
        await FirebaseFirestore.instance
            .collection('services')
            .doc(widget.service.id)
            .update({
          'name': serviceName,
          'description': serviceDescription,
          'depositPrice': serviceDepositPrice,
          'categoryId': selectedCategoryId, // Update the category ID
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الخدمة بنجاح')),
        );
        Navigator.pop(context); // Close the edit screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تحديث الخدمة')),
        );
      } finally {
        setState(() {
          isLoading = false; // Hide loader
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        appBar: AppBar(
          title: const Text('تعديل الخدمة'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _serviceNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الخدمة',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال اسم الخدمة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _serviceDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'وصف الخدمة',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال وصف الخدمة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _serviceDepositPriceController,
                    decoration: const InputDecoration(
                      labelText: 'سعر الخدمة',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال سعر الخدمة';
                      }
                      if (double.tryParse(value) == null) {
                        return 'يرجى إدخال قيمة صحيحة للسعر';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Searchable dropdown for categories using flutter_typeahead
                  TypeAheadField(
                    controller: _categoryController,
                    suggestionsCallback: (pattern) async {
                      return categories
                          .where((category) => category['name']
                          .toLowerCase()
                          .contains(pattern.toLowerCase()))
                          .toList();
                    },
                    itemBuilder: (context, suggestion) {
                      final category = suggestion as Map<String, dynamic>;
                      return ListTile(
                        title: Text(category['name']),
                      );
                    },
                    onSelected: (suggestion) {
                      final category = suggestion as Map<String, dynamic>;
                      setState(() {
                        selectedCategoryId = category['id'];
                        _categoryController.text = category['name'];
                      });
                    },
                    // textFieldConfiguration: TextFieldConfiguration(
                    //   decoration: const InputDecoration(
                    //     labelText: 'اختر الفئة',
                    //     border: OutlineInputBorder(),
                    //   ),
                    // ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    buildSpinKitFadingCircle(),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _updateService,
                    child: const Text('تحديث الخدمة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}