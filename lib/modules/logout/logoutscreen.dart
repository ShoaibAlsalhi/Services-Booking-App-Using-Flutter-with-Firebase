// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// import '../login/login_screen.dart';
//
// class LogoutScreen extends StatelessWidget {
//   const LogoutScreen({super.key});
//
//   void _logout(BuildContext context) async {
//     try {
//       await FirebaseAuth.instance.signOut();
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) =>  LoginScreen()),
//             (route) => false,
//       );
//     } catch (e) {
//       debugPrint('Error during logout: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               const Icon(Icons.error, color: Colors.white),
//               const SizedBox(width: 10),
//               Expanded(child: Text('Logout failed. Please try again.')),
//             ],
//           ),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Logout'),
//         centerTitle: true,
//       ),
//       body: Center(
//         child: ElevatedButton.icon(
//           onPressed: () => _logout(context),
//           icon: const Icon(Icons.logout),
//           label: const Text('Logout'),
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           ),
//         ),
//       ),
//     );
//   }
// }
