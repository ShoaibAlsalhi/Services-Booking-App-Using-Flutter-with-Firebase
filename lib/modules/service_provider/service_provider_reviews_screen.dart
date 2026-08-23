import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:motion/motion.dart';
import 'package:service_booking_app/shared/styles/colors.dart';

import '../../shared/components/components.dart';

class ServiceProviderReviewsScreen extends StatelessWidget {
  final String providerId;

  const ServiceProviderReviewsScreen({Key? key, required this.providerId})
      : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchReviews() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(providerId)
        .collection('ratings')
        .orderBy('timestamp', descending: true)
        .get();
    List<Map<String, dynamic>> reviews = [];
    for (var doc in querySnapshot.docs) {
      var reviewData = doc.data();
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(reviewData['userId'])
          .get();

      if (userSnapshot.exists) {
        reviewData['userName'] = userSnapshot['name'] ?? 'مستخدم مجهول';
      } else {
        reviewData['userName'] = 'مستخدم مجهول';
      }
      reviews.add(reviewData);
    }
    return reviews;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: defaultBackgroundColor,
        // appBar: AppBar(
        //   title: const Text('التقييمات والتعليقات الخاصة بك'),
        //   backgroundColor: Colors.teal,
        // ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchReviews(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return buildSpinKitFadingCircle();
            }
      
            if (snapshot.hasError) {
              return Center(
                child: Text('حدث خطأ: ${snapshot.error}'),
              );
            }
      
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('لا توجد تقييمات حتى الآن.'),
              );
            }
      
            final reviews = snapshot.data!;
      
            return ListView.builder(
              padding: const EdgeInsets.all(5.0),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review['userName'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                // color: Colors.teal,
                              ),
                            ),
                            RatingBarIndicator(
                              rating: (review['rating'] ?? 0).toDouble(),
                              itemCount: 5,
                              itemSize: 20.0,
                              direction: Axis.horizontal,
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          review['comment'] ?? 'لا يوجد تعليق.',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'التاريخ: ${review['timestamp']?.toDate() ?? 'غير متوفر'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
