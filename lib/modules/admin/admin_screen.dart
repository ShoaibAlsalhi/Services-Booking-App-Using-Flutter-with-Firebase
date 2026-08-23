import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Import animations package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_booking_app/modules/admin/service_management_screen.dart';
import 'package:service_booking_app/modules/admin/view_all_users_screen/view_all_users_screen.dart';
import 'package:service_booking_app/modules/logout/logoutscreen.dart';

import '../../shared/components/components.dart';
import '../../shared/styles/colors.dart';
import 'AdminCategoryServiceManagementScreen.dart';
import 'account_upgrade_requests_screen.dart';
import 'add_payment_method_screen/add_payment_method_screen.dart';
import 'add_payment_method_screen/manage_payment_method_screen.dart';
import 'advertisement_screen/list_advertisement_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        appBar: AppBar(
          title: const Text('لوحة التحكم'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => showLogoutConfirmationDialog(context),
            ),
          ],
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
                  _buildStatisticsCards(),
                  const SizedBox(height: 24),
                  const Text('إدارة الخدمات والمستخدمين', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildManagementGrid(context),
                  const SizedBox(height: 24),
                  const Text('الأنشطة الأخيرة', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildRecentActivities(),
                ],
              ),
            ),
          ),
        ),
        drawer: _buildNavigationDrawer(context),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 500),
          childAnimationBuilder: (widget) => ScaleAnimation(
            scale: 0.5, // Scale up from 50% to 100%
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('العملاء\n', Icons.people, Colors.blue, Colors.blue[50]!),
                _buildStatCard('مزودو الخدمة', Icons.business, Colors.green, Colors.green[50]!),
                _buildStatCard('المواعيد اليومية', Icons.calendar_today, Colors.orange, Colors.orange[50]!),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('الحسابات \nالنشطة', Icons.check_circle, Colors.green, Colors.green[50]!),
                _buildStatCard('الحسابات \nغير النشطة', Icons.cancel, Colors.red, Colors.red[50]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, IconData icon, Color color, Color circleAvatarColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.0)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(radius: 33, backgroundColor: circleAvatarColor, child: Icon(icon, size: 40, color: color)),
              const SizedBox(height: 8),
              Center(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              FutureBuilder<int>(
                future: _fetchCount(title),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return buildSpinKitFadingCircle();
                  if (snapshot.hasError) return const Text('خطأ');
                  return Text('${snapshot.data ?? 0}', style: const TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<int> _fetchCount(String type) async {
    String collection = 'users';
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (type) {
      case 'العملاء\n':
        return FirebaseFirestore.instance.collection(collection).where('userRole', isEqualTo: 'customer').get().then((snapshot) => snapshot.docs.length);
      case 'مزودو الخدمة':
        return FirebaseFirestore.instance.collection(collection).where('userRole', isEqualTo: 'service_provider').get().then((snapshot) => snapshot.docs.length);
      case 'المواعيد اليومية':
        return FirebaseFirestore.instance.collection('bookings').where('timestamp', isGreaterThanOrEqualTo: startOfDay).where('timestamp', isLessThanOrEqualTo: endOfDay).get().then((snapshot) => snapshot.docs.length);
      case 'الحسابات \nالنشطة':
        return FirebaseFirestore.instance.collection(collection).where('account_status', isEqualTo: true).get().then((snapshot) => snapshot.docs.length);
      case 'الحسابات \nغير النشطة':
        return FirebaseFirestore.instance.collection(collection).where('account_status', isEqualTo: false).get().then((snapshot) => snapshot.docs.length);
      default:
        return 0;
    }
  }

  Widget _buildManagementGrid(BuildContext context) {
    return AnimationLimiter(
      child: GridView.count(
        crossAxisCount: 3, // عرض ثلاث عمليات في كل صف
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 500),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0, // Slide from the bottom
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: [
            _buildManagementCard(icon: Icons.manage_accounts, title: 'إدارة \nالمستخدمين', color: Colors.blue, circleAvatarColor: Colors.blue[50]!, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminViewUsersScreen()))),
            _buildManagementCard(icon: Icons.miscellaneous_services_outlined, title: 'إدارة \nالخدمات', color: Colors.green, circleAvatarColor: Colors.green[50]!, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminCategoryServiceManagementScreen()))),
            _buildManagementCard(icon: Icons.stacked_line_chart, title: 'طلبات \nالترقية', color: Colors.pink, circleAvatarColor: Colors.pink[50]!, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminUpgradeRequestsScreen()))),
            _buildManagementCard(icon: Icons.payment, title: 'إدارة طرق\n الدفع', color: Colors.deepOrange, circleAvatarColor: Colors.deepOrange[50]!, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentMethodsScreen()))),
            _buildManagementCard(icon: Icons.campaign, title: 'إدارة \nالإعلانات', color: Colors.purple, circleAvatarColor: Colors.purple[50]!, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdvertisementsListScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard({required IconData icon, required String title, required Color color, required Color circleAvatarColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 25, backgroundColor: circleAvatarColor, child: Icon(icon, size: 25, color: color)),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('activities').orderBy('timestamp', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return buildSpinKitFadingCircle();
        if (snapshot.hasError) return const Text('خطأ في تحميل الأنشطة');
        final activities = snapshot.data?.docs ?? [];
        if (activities.isEmpty) return const Text('لا توجد أنشطة حديثة.');

        return AnimationLimiter(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index].data() as Map<String, dynamic>;
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  horizontalOffset: 50.0, // Slide from the right
                  child: FadeInAnimation(
                    child: ListTile(
                      leading: const Icon(Icons.event, color: Colors.teal),
                      title: Text(activity['description'] ?? 'غير متوفر'),
                      subtitle: Text(activity['timestamp'] != null ? (activity['timestamp'] as Timestamp).toDate().toString() : ''),
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

  Widget _buildNavigationDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.admin_panel_settings, size: 60, color: Colors.white),
                SizedBox(height: 8),
                Text('لوحة تحكم المدير', style: TextStyle(color: textColor, fontSize: 20)),
              ],
            ),
          ),
          ListTile(leading: const Icon(Icons.report), title: const Text('التقارير'), onTap: () {}),
          ListTile(leading: const Icon(Icons.logout), title: const Text('تسجيل الخروج'), onTap: () {}),
        ],
      ),
    );
  }
}