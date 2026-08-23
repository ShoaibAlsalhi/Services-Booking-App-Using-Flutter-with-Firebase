import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';

import '../../cubits/customer_cubit/sub_cubits/category_cubit/category_cubit.dart';
import '../../cubits/customer_cubit/sub_cubits/category_cubit/category_state.dart';
import '../../models/advertisement_model/advertisement_model.dart';
import '../../models/services_models.dart'; // Import the ServiceCategory model
import '../../shared/components/components.dart';
import '../../shared/styles/colors.dart';
import 'customer_list_services_screen.dart';

import 'package:carousel_slider/carousel_slider.dart';


class CustomerListCategoryScreen extends StatelessWidget {
  const CustomerListCategoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
     const colorizeColors = [
      Colors.deepOrange,
      Colors.amber,
      Colors.yellow,
      Colors.red,
    ];
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CategoryCubit()..fetchCategoriesRealTime()),
        BlocProvider(create: (_) => AdvertisementCubit()..fetchAdvertisements()),
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: defaultBackgroundColor,
          body: SingleChildScrollView(
            child: Column(
              children: [
                BlocBuilder<AdvertisementCubit, AdvertisementState>(
                  builder: (context, adState) {
                    if (adState is AdvertisementLoaded && adState.ads.isNotEmpty) {
                      return CarouselSlider(
                        options: CarouselOptions(
                          height: 200,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 0.9,
                          aspectRatio: 2.0,
                        ),
                        items: adState.ads.map((AdvertisementModel ad) {
                          return Builder(
                            builder: (BuildContext context) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  buildeCachedNetworkImage(
                                    url: ad.imageUrl,
                                    width: MediaQuery.of(context).size.width,
                                    fit: BoxFit.cover,
                                    borderRadius: 10,
                                  ),
                                  // Dark gradient overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.7),
                                          Colors.black.withOpacity(0.2),
                                          Colors.black.withOpacity(0.7),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                  // Text container
                                  Positioned(
                                    bottom: 20,
                                    right: 16,
                                    left: 16,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AnimatedTextKit(
                                            animatedTexts: [

                                              ColorizeAnimatedText(
                                                speed: Duration(seconds: 1),
                                                ad.title,                                                textStyle: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.deepOrangeAccent,
                                                ),
                                                textAlign: TextAlign.center,
                                                colors: colorizeColors,
                                              ),
                                            ],
                                            repeatForever: true, // Repeat the animation forever
                                          ),


                                          const SizedBox(height: 4),
                                          Text(
                                            ad.description,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 15,
                                              height: 1.4,
                                              shadows: [
                                                Shadow(color: Colors.black54, blurRadius: 2),
                                              ],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        }).toList(),
                      );
                    } else if (adState is AdvertisementLoading) {
                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: buildSpinKitFadingCircle(),
                      );
                    } else if (adState is AdvertisementError) {
                      return Text("خطأ أثناء تحميل الإعلانات: ${adState.message}");
                    }
                    return const SizedBox(height: 180); // Placeholder height
                  },
                ),
                // Wrap the Category section inside the Expanded widget to handle scrolling
                BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, state) {
                    final categoryCubit = CategoryCubit.get(context);
                    if (state is CategoryLoading) {
                      return buildSpinKitFadingCircle();
                    }
                    if (state is CategoryError) {
                      return Center(child: Text(state.message));
                    }
                    if (state is CategoryEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset('assets/animation/offline.json', width: 64, height: 64),
                            const SizedBox(height: 16),
                            const Text("يرجى التحقق من الاتصال بالإنترنت.", style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: categoryCubit.fetchCategoriesRealTime,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              ),
                              child: const Text("إعادة المحاولة", style: TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state is CategoryLoaded) {
                      final categories = categoryCubit.categories;
                      if (categories == null || categories.isEmpty) {
                        return const Center(child: Text('لم يتم العثور على فئات.'));
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10,),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Text("فئات الخدمات",
                            style: TextStyle(fontSize: 22,fontWeight: FontWeight.bold),
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = (constraints.maxWidth / 180).floor();
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(8),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 8.0,
                                  mainAxisSpacing: 8.0,
                                  childAspectRatio: 2 / 2.5,
                                ),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  return AnimationConfiguration.staggeredGrid(
                                    position: index,
                                    duration: const Duration(milliseconds: 500),
                                    columnCount: crossAxisCount,
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: _CategoryCard(
                                          category: category,
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CustomerListServicesScreen(
                                                categoryId: category.id,
                                                categoryName: category.name,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      );
                    }
                    return Container();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ServiceCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the category image if available, otherwise show a default icon in a CircleAvatar
            if (category.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: buildeCachedNetworkImage(
                  url: category.imageUrl!,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              )
            else
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.red[50],
                child: const Icon(Icons.design_services, color: Colors.deepOrange, size: 30),
              ),
            const SizedBox(height: 10),
            Text(
              category.name.split(' ').join('\n'),
              maxLines: 3,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              backgroundColor: Colors.red[50],
              child: const Icon(Icons.arrow_back, color: Colors.deepOrange, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}





///////////////////////////////////////////////




class AdvertisementCubit extends Cubit<AdvertisementState> {
  AdvertisementCubit() : super(AdvertisementInitial());

  static AdvertisementCubit get(context) => BlocProvider.of(context);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void fetchAdvertisements() {
    emit(AdvertisementLoading());
    _firestore.collection('advertisements').snapshots().listen((snapshot) {
      final ads = snapshot.docs
          .map((doc) => AdvertisementModel.fromMap(doc.data(), doc.id))
          .toList();
      emit(AdvertisementLoaded(ads));
    }, onError: (error) {
      emit(AdvertisementError(error.toString()));
    });
  }
}


///////////////////////////////////////////////////



abstract class AdvertisementState {}

class AdvertisementInitial extends AdvertisementState {}

class AdvertisementLoading extends AdvertisementState {}

class AdvertisementLoaded extends AdvertisementState {
  final List<AdvertisementModel> ads;

  AdvertisementLoaded(this.ads);
}

class AdvertisementError extends AdvertisementState {
  final String message;

  AdvertisementError(this.message);
}
