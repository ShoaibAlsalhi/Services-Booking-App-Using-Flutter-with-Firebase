import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:service_booking_app/shared/styles/colors.dart';

import '../../../models/user_model/user_model.dart';
import '../../../shared/components/components.dart';
import '../../service_provider/manage_booking_screen/manage_booking_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Import animations package
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminViewUsersScreen extends StatefulWidget {
  const AdminViewUsersScreen({Key? key}) : super(key: key);

  @override
  _AdminViewUsersScreenState createState() => _AdminViewUsersScreenState();
}

class _AdminViewUsersScreenState extends State<AdminViewUsersScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        appBar: AppBar(
          title: const Text('إدارة المستخدمين'),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'عملاء'),
              Tab(text: 'مزودو الخدمات'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildUserList('customer'),
            _buildUserList('service_provider'),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').where('userRole', isEqualTo: role).snapshots(),
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

        final users = snapshot.data?.docs.map((doc) {
          return UserModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
        }).toList() ?? [];

        if (users.isEmpty) {
          return const Center(child: Text('لا توجد بيانات.'));
        }

        return AnimationLimiter(
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isInactive = user.account_status == false;

              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  verticalOffset: 50.0, // Slide from the bottom
                  child: FadeInAnimation(
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to UserDetailScreen with selected user
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserDetailScreen(user: user),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 7),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            // User Image
                            ClipOval(
                              child: buildeCachedNetworkImage(
                                url: user.imageUrl.toString(),
                                width: 70,
                                height: 70,
                                borderRadius: 50,
                                fit: BoxFit.cover
                              ),
                            ),
                            const SizedBox(width: 10),
                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isInactive ? Colors.red : Colors.black,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    user.userRole == 'service_provider'
                                        ? 'مزود خدمة'
                                        : user.userRole == 'customer'
                                        ? 'عميل'
                                        : 'Unknown Role',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isInactive ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Status Indicator
                            CircleAvatar(
                              backgroundColor: isInactive ? Colors.red[50] : Colors.green[50],
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: isInactive ? Colors.red : Colors.green,
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
          ),
        );
      },
    );
  }
}




///////////////////////////////////







class UserDetailScreen extends StatefulWidget {
  final UserModel user;
  const UserDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _accountStatus = false;
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _accountStatus = widget.user.account_status;
    _userRole = widget.user.userRole;
  }

  void _updateAccountStatus(bool status) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.id)
        .update({'account_status': status});

    setState(() {
      _accountStatus = status;
    });
  }

  void _upgradeUserRole() async {
    if (_userRole == 'customer') {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({'userRole': 'service_provider'});

      setState(() {
        _userRole = 'service_provider';
      });
    }
  }

  void _navigateToBookings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceProviderBookingsScreen(providerId: widget.user.id, isAdmin: true),
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
          title: Text('تفاصيل المستخدم: ${widget.user.name}'),
          backgroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10.0),
          child: AnimationLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 500),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0, // Slide from the bottom
                  child: FadeInAnimation(
                    child: widget,
                  ),
                ),
                children: [
                  _buildUserInfoCard(),
                  const SizedBox(height: 16),
                  _buildAccountStatusToggle(),
                  const SizedBox(height: 16),
                  if (_userRole == 'customer') _buildUpgradeButton(),
                  const SizedBox(height: 16),
                  if (_userRole == 'service_provider') _buildViewBookingsButton(),
                  const SizedBox(height: 16),
                  if (_userRole == 'service_provider') buildAllCommentsAndRatings(userId: widget.user.id),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.person, widget.user.name), // Username icon
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email, widget.user.email), // Email icon
            const SizedBox(height: 8),
            _buildInfoRow(Icons.verified_user, _userRole == 'customer' ? 'عميل' : 'مزود خدمة'), // Role icon
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.deepOrange[50],
          child: Icon(icon, size: 24, color: Colors.deepOrange),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountStatusToggle() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'الحالة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Switch(
              value: _accountStatus,
              activeColor: Colors.deepOrange,
              onChanged: (status) {
                _updateAccountStatus(status);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return Center(
      child: buildElevatedButton(
        onPressed: _upgradeUserRole,
        child: Text(
          'ترقية إلى مزود خدمة',
        ),
        width: 250,
        height: 45,
      ),
    );
  }

  Widget _buildViewBookingsButton() {
    return Center(
      child: buildElevatedButton(
        onPressed: _navigateToBookings,
        child: Text(
          'عرض حجوزات المزود',
        ),
        width: 250,
        height: 45,
      ),
    );
  }
}