import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Import animations package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../shared/components/components.dart';

class ProviderRatingsScreen extends StatefulWidget {
  final String providerId;

  const ProviderRatingsScreen({
    Key? key,
    required this.providerId,
  }) : super(key: key);

  @override
  _ProviderRatingsScreenState createState() => _ProviderRatingsScreenState();
}

class _ProviderRatingsScreenState extends State<ProviderRatingsScreen> {
  final _commentController = TextEditingController();
  double _rating = 0;
  bool _hasRated = false;
  bool _showRatingInput = false; // To control visibility of rating input fields

  @override
  void initState() {
    super.initState();
    _checkIfUserHasRated();
  }

  // Function to get the current user's ID
  Future<String> _getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;
    }
    return '';
  }

  // Check if the user is logged in
  Future<bool> isUserLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    return user != null; // Returns true if the user is logged in
  }

  // Check if the user has already rated and commented
  Future<void> _checkIfUserHasRated() async {
    final userId = await _getCurrentUserId();
    if (userId.isNotEmpty) {
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(widget.providerId)
          .collection('ratings')
          .doc(userId)
          .get();

      if (ratingsSnapshot.exists) {
        setState(() {
          _hasRated = true;
          _rating = ratingsSnapshot['rating'];
          _commentController.text = ratingsSnapshot['comment'];
        });
      }
    }
  }

  // Submit rating and comment
  Future<void> _submitRatingAndComment() async {
    final userId = await _getCurrentUserId();

    // Check if rating or comment is missing
    if (_rating == 0 || _commentController.text.isEmpty) {
      // Display an error message if either field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تقديم التقييم والتعليق'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Prevent submission
    }

    if (userId.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('service_providers')
          .doc(widget.providerId)
          .collection('ratings')
          .doc(userId)
          .set({
        'rating': _rating,
        'comment': _commentController.text,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _hasRated = true;
        _showRatingInput = false; // Hide the input fields after submission
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التعليقات والتقييمات'),
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
                  verticalOffset: 50.0, // Slide from the bottom
                  child: FadeInAnimation(
                    child: widget,
                  ),
                ),
                children: [
                  if (!_hasRated) _buildRatingPrompt(), // Show the call-to-action prompt
                  if (_showRatingInput) _buildRatingAndComment(), // Show the rating input fields
                  _buildUserCommentAndRating(),
                  buildAllCommentsAndRatings(userId: widget.providerId),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Call-to-action prompt to guide the user to leave a rating and comment
  Widget _buildRatingPrompt() {
    return GestureDetector(
      onTap: () async {
        // Check if the user is logged in
        final isLoggedIn = await isUserLoggedIn();
        if (!isLoggedIn) {
          // If the user is not logged in, show the login/sign-up dialog
          showLoginSignUpDialog(context);
          return;
        }

        // If the user is logged in, show the rating input fields
        setState(() {
          _showRatingInput = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 30,
            ),
            const SizedBox(width: 10),
            const Text(
              'اضغط هنا لتقييم المزود وترك تعليق',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Rating and Comment input widget using flutter_rating_bar
  Widget _buildRatingAndComment() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            const SizedBox(height: 20),
            const Text('قيم المزود:'),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 0,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 40.0,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'اكتب تعليقك هنا...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (text) {
                // This will ensure the comment is updated in the controller
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _submitRatingAndComment();
              },
              child: const Text('أرسل التقييم'),
            ),
          ],
        );
      },
    );
  }

  // Display the comment and rating of the current user
  Widget _buildUserCommentAndRating() {
    if (_hasRated) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('تعليقك وتقييمك:'),
          Text('التقييم: $_rating'),
          Text('التعليق: ${_commentController.text}'),
        ],
      );
    }
    return Container();
  }


  // Skeleton loading widget
  Widget _buildSkeletonLoading() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 500),
          child: SlideAnimation(
            verticalOffset: 50.0, // Slide from the bottom
            child: FadeInAnimation(
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                  ),
                  title: Container(
                    width: 100,
                    height: 16,
                    color: Colors.grey[300],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 150,
                        height: 14,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        height: 14,
                        color: Colors.grey[300],
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
  }
}