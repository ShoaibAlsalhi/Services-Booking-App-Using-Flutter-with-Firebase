import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Import animations package
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/upgrade_account_request_model/upgrade_account_request_model.dart';
import '../../shared/components/components.dart';
import '../../shared/styles/colors.dart';

class AdminUpgradeRequestsScreen extends StatefulWidget {
  const AdminUpgradeRequestsScreen({Key? key}) : super(key: key);

  @override
  _AdminUpgradeRequestsScreenState createState() =>
      _AdminUpgradeRequestsScreenState();
}

class _AdminUpgradeRequestsScreenState
    extends State<AdminUpgradeRequestsScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  late Stream<QuerySnapshot> _allRequestsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _allRequestsStream = _firestore.collection('upgradeRequests').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'طلبات ترقية الحسابات',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          backgroundColor: defaultBackgroundColor,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'جديدة'),
              Tab(text: 'مقبولة'),
              Tab(text: 'مرفوضة'),
            ],
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRequestList('New'),
            _buildRequestList('Excepted'),
            _buildRequestList('Rejected'),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('upgradeRequests')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildSpinKitFadingCircle();
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'خطأ: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final requests = snapshot.data?.docs.map((doc) {
          return UpgradeRequestModel.fromFirestore(doc);
        }).toList() ?? [];

        if (requests.isEmpty) {
          return const Center(child: Text('لا توجد طلبات.'));
        }

        return AnimationLimiter(
          child: ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  verticalOffset: 50.0, // Slide from the bottom
                  child: FadeInAnimation(
                    child: FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(request.userId).get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return buildSpinKitFadingCircle();
                        }

                        if (userSnapshot.hasError) {
                          return Text('Error: ${userSnapshot.error}');
                        }

                        final userData = userSnapshot.data;
                        final userName = userData != null ? userData['name'] : 'User not found';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          shadowColor: Colors.black.withOpacity(0.2),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              'طلب من المستخدم: $userName',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('الرسالة: ${request.requestMessage}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'الحالة: ${request.status}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(width: 10),
                                if (status == 'New') BuildExceptedIconButton(request.userId),
                                if (status == 'New') BuildRejectedIconButton(request.userId),
                                if (status == 'Excepted') BuildRejectedIconButton(request.userId),
                                if (status == 'Rejected') BuildExceptedIconButton(request.userId),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget BuildExceptedIconButton(String userId) =>
      Padding(
        padding: const EdgeInsets.only(left: 5),
        child: CircleAvatar(
          maxRadius: 20,
          backgroundColor: Colors.green[100],
          child: IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () {
              _showConfirmationDialog(userId, 'Excepted');
            },
          ),
        ),
      );

  Widget BuildRejectedIconButton(String userId) =>
      CircleAvatar(
        maxRadius: 20,
        backgroundColor: Colors.red[100],
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () {
            _showConfirmationDialog(userId, 'Rejected');
          },
        ),
      );

  void _showConfirmationDialog(String userId, String status) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'هل أنت متأكد؟',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('هل ترغب حقًا في تحديد حالة هذا الطلب كـ $status؟'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateRequestStatus(userId, status);
              },
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateRequestStatus(String userId, String status) async {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('معرف المستخدم غير صالح!'),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      // Update the upgrade request status
      await _firestore.collection('upgradeRequests').doc(userId).update({
        'status': status,
      });

      // Update the user role in the 'users' collection based on the status
      String userRole = (status == 'Excepted') ? 'service_provider' : 'customer';
      await _firestore.collection('users').doc(userId).update({
        'userRole': userRole,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم $status الطلب وتحديث صلاحية المستخدم'),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحديث الطلب: $e'),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}