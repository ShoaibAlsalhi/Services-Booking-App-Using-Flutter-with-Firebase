import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lottie/lottie.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:service_booking_app/modules/login/login_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/on_Boarding/on_BoardingModel.dart';
import '../../models/services_models.dart';
import '../../modules/sign_up/sign_up_screen.dart';

Widget buildElevatedButton({
  required VoidCallback onPressed,
  required Widget child,
  double height = 50.0,
  double width = double.infinity,
  Color backgroundColor = Colors.blue,
  double borderRadius = 8.0, // Added radius parameter with a default value
  TextStyle? textStyle, // Added textStyle parameter
}) {
  const defaultTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
  );

  return SizedBox(
    height: height,
    width: width,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>( Color(0xFFFF7643)),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: textStyle ?? defaultTextStyle,
        // Use specified textStyle or defaultTextStyle
        child: child,
      ),
    ),
  );
}

// Call the function

// buildElevatedButton(
// onPressed: () {
// // onPressed function here
// print('Button pressed');
// },
// child: Text('Text Goes here'),
// textStyle: TextStyle(
// color: Colors.black,
// fontSize: 18.0,
// fontWeight: FontWeight.normal),
// ),






Widget buildTextFormField({
  required TextEditingController controller,
  required String labelText,
   IconData? iconData,
  required TextInputType keyboardType,
  bool obscureText = false,
  Widget? suffixIcon,
  String? Function(String?)? validator,
  String? Function(String?)? onChanged,
  Color iconColor = const Color(0xFFED6B00),
  int maxLines = 1,
  String? errorText

}) {
  return Container(
    padding: const  EdgeInsets.all(10),
    decoration: BoxDecoration(
      // color: Colors.black87,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color:  Color(0xFFFF7643)),

    ),
    child: Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: labelText,
              icon: Icon(iconData,color: iconColor,),
              suffixIcon: suffixIcon,
              labelStyle: const TextStyle(color: Color(0xFFED6B00)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              errorText: errorText,
            ),
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            onChanged: onChanged,

          )
        ),
      ],
    ),
  );
}


void navigateTo(context, widget) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => widget,
    ));

/// Navigate to a specific screen
void replacementNavigateTo(BuildContext context, Widget screen) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => screen),
  );
}

Widget buildTextButton({
  required VoidCallback onPressed,
  required String text,
  Color color = Colors.blue,
}) {
  return TextButton(
    onPressed:onPressed,
    child: Text(text,style: TextStyle(color:color, fontWeight: FontWeight.bold,fontSize: 16.0 ),),
  );
}






// void buildToast(String message , ToastState state)
// {
//    Fluttertoast.showToast(
//       msg: message,
//       toastLength: Toast.LENGTH_LONG,
//       gravity: ToastGravity.BOTTOM,
//       timeInSecForIosWeb: 5,
//       backgroundColor:getToastColor(state),
//       textColor: Colors.white,
//       fontSize: 16.0
//   );
// }

/// Show snackbar for error or info messages
void showToastService(
    {required BuildContext context,
      required String message,
      required Color color,
      IconData? iconData,
    }
    ) {

  ToastService.showToast(
    context,
    // isClosable: true,
    backgroundColor: color,
    // shadowColor: Colors.teal.shade200,
    length: ToastLength.medium,
    expandedHeight: 100,
    message: "$message !",
    messageStyle: TextStyle(fontSize: 15,color: Colors.white),
    leading:  Icon(iconData,size: 30,color: Colors.white,),
    slideCurve: Curves.elasticInOut,
    positionCurve: Curves.bounceOut,
    dismissDirection: DismissDirection.none,
  );
}



void showErrorMessageDialog(String message, String lottieAnimationPath,BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Center(
            child: Lottie.asset(
              lottieAnimationPath,
              repeat: true,
              reverse: true,
              width: 70,
              height: 70,
            ),
          ),
          content: Text(message),
          actions: <Widget>[
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('حسناً'),
              ),
            ),
          ],
        ),
      );
    },
  );
}




// Display all comments and ratings for every specific provider
Widget buildAllCommentsAndRatings({required String userId}) {
  return FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance
        .collection('service_providers')
        .doc(userId)
        .collection('ratings')
        .orderBy('timestamp', descending: true)
        .get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildSkeletonLoading(); // Show skeleton while loading
      }

      if (snapshot.hasError) {
        return Center(child: Text('خطأ: ${snapshot.error}'));
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('لا توجد تعليقات بعد.'));
      }

      final comments = snapshot.data!.docs.map((doc) {
        final rating = doc['rating'] ?? 0;
        final comment = doc['comment'] ?? 'لا تعليق';
        final userId = doc['userId'] ?? '';

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return _buildSkeletonLoading(); // Show skeleton while loading
            }

            if (userSnapshot.hasError) {
              return Center(child: Text('خطأ في تحميل اسم المستخدم'));
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Center(child: Text('اسم المستخدم غير موجود'));
            }

            final userName = userSnapshot.data!['name'] ?? 'مستخدم مجهول';
            final userImageUrl = userSnapshot.data!['imageUrl'] ?? 'مستخدم مجهول';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: buildeCachedNetworkImage(url:userImageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover
                ),
                title: Row(
                  children: [
                    RatingBarIndicator(
                      rating: rating.toDouble(),
                      itemCount: 5,
                      itemSize: 22.0,
                      direction: Axis.horizontal,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'التقييم: $rating',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'من: $userName',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comment,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }).toList();

      return Column(
        children: comments,
      );
    },
  );
}

// Skeleton loading UI
Widget _buildSkeletonLoading() {
  return Skeletonizer(
    enabled: true,
    child: Column(
      children: List.generate(3, (index) => _buildSkeletonItem()), // Show 3 skeleton items
    ),
  );
}

// Skeleton for comment card
Widget _buildSkeletonItem() {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(10),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: ClipOval(
        child: Container(
          width: 50,
          height: 50,
          color: Colors.grey[300], // Placeholder for image
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 100,
            height: 16,
            color: Colors.grey[300], // Placeholder for rating
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Container(
            width: 150,
            height: 14,
            color: Colors.grey[300], // Placeholder for username
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            height: 14,
            color: Colors.grey[300], // Placeholder for comment text
          ),
        ],
      ),
    ),
  );
}







//
Widget buildLotile(
    {required String path,
      double width = 70,
      double height = 70}) {
  return Lottie.asset(
    path,
    repeat: true,
    reverse: true,
    width: width,
    height: height,
  );
}

Widget buildeCachedNetworkImage({
  required String url,
  double width = double.infinity,
  double height = 200,
  double borderRadius = 50,
  BoxFit? fit,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: CachedNetworkImage(
      imageUrl: url,
      placeholder: (context, url) => buildSpinKitFadingCircle(),
      errorWidget: (context, url, error) => Image.asset(
        'assets/img/fallback_image.jpg',
        width: width,
        height: height,
        fit: fit
      ), width: width,
      height: height,
      fit: fit, // Add the fit parameter here
    ),
  );
}




Future<void> logout(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    replacementNavigateTo(context,  LoginScreen());
  } catch (e) {
    print("Error during logout: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to log out: $e')),
    );
  }
}

// Function to show the confirmation dialog
Future<void> showLogoutConfirmationDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return Directionality(
        textDirection: TextDirection.rtl, // Set text direction to RTL
        child: AlertDialog(
          title: Text('تأكيد تسجيل الخروج',style: TextStyle(fontFamily: 'myFont', fontSize: 16),),
          content: Text('هل تريد تسجيل الخروج بالفعل؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // إغلاق النافذة
              },
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // إغلاق النافذة
                logout(context); // المتابعة بتسجيل الخروج
              },
              child: Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    },
  );
}







/// Checks if the user is logged in.
Future<bool> isUserLoggedIn() async {
  // Example: Check Firebase Authentication
  final user = FirebaseAuth.instance.currentUser;
  return user != null; // Returns true if the user is logged in
}




void showLoginSignUpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل الدخول أو إنشاء حساب',style: TextStyle(fontFamily: 'myFont'),),
          content: const Text('يجب عليك تسجيل الدخول أو إنشاء حساب لتتمكن من التقييم والتعليق.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: const Text('تسجيل الدخول'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
              child: const Text('إنشاء حساب'),
            ),
          ],
        ),
      );
    },
  );
}




void showDescriptionDialog(BuildContext context, String description) {
  showDialog(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl, // Ensure text is RTL
        child: AlertDialog(
          title: const Text(
            'وصف المشكلة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text(
                'إغلاق',
                style: TextStyle(color: Colors.deepOrange),
              ),
            ),
          ],
        ),
      );
    },
  );
}


void launchPhoneCall(String phoneNumber) async {
  if (phoneNumber != null && phoneNumber.isNotEmpty) {
    final Uri phoneLaunchUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(phoneLaunchUri)) {
      await launchUrl(phoneLaunchUri);
    } else {
      throw 'Could not launch $phoneLaunchUri';
    }
  }
}




void buildQuickAlertDialog({
  required BuildContext context,
  required String message,
  required QuickAlertType alertType, // Add parameter for alert type
  required String title,            // Add parameter for title
  required String confirmBtnText,   // Add parameter for confirm button text
  required Color confirmBtnColor,   // Add parameter for confirm button color
  required VoidCallback onConfirmBtnTap, // Add parameter for onConfirmBtnTap
}) {
  QuickAlert.show(
    context: context,
    type: alertType, // Use the passed alert type
    title: title,    // Use the passed title
    text: message,
    confirmBtnText: confirmBtnText, // Use the passed confirm button text
    confirmBtnColor: confirmBtnColor, // Use the passed confirm button color
    onConfirmBtnTap: onConfirmBtnTap, // Use the passed onConfirmBtnTap function
  );
}

Widget buildSpinKitFadingCircle()
{
  return Center(
    child: SpinKitFadingCircle(
      color: Colors.deepOrange,
      size: 50.0,
    ),
  );
}





