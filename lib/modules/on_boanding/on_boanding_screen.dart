import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:animated_text_kit/animated_text_kit.dart'; // Import animated_text_kit

import '../../cubits/login_cubit/login_cubit.dart';
import '../../cubits/login_cubit/login_states.dart';
import '../../layout/customer_layout.dart';
import '../../models/on_Boarding/on_BoardingModel.dart';
import '../../shared/components/components.dart';
import '../../shared/network/local/cache_helper.dart';
import '../../shared/styles/colors.dart';

class OnBoardingScreen extends StatelessWidget {
  final List<BoardingModel> boarding = [
    BoardingModel(
      image: 'assets/animation/on_boarding1.json',
      title: 'مرحبًا بك',
      body:
      "اكتشف الطريقة الأسهل لإدارة مواعيدك مع مزودي الخدمات الموثوقين. تطبيقنا يوفر لك تجربة فريدة تركز على راحتك وسهولة استخدامك. انضم الآن وابدأ رحلتك نحو تجربة حجز غير مسبوقة!",
    ),
    BoardingModel(
      image: 'assets/animation/on_boarding2.json',
      title: 'سهل الاستخدام',
      body:
      "مع تطبيق المستقل اليمني، أصبح العثور على الخدمات المناسبة أسهل من أي وقت مضى. تصفح مئات الخيارات، اختر الأنسب لك، واحجز الموعد المثالي بضغطة واحدة. كل ذلك في مكان واحد، من هاتفك فقط!",
    ),
    BoardingModel(
      image: 'assets/animation/on_boarding3.json',
      title: 'كل شيء تحت سيطرتك',
      body:
      "لا مزيد من الفوضى أو القلق! يوفر لك التطبيق لوحة تحكم كاملة لإدارة حجوزاتك، مراجعة مواعيدك، وتتبع تقدم خدماتك بكل بساطة. استمتع بتنظيم حياتك بالطريقة التي تستحقها",
    ),
    BoardingModel(
      image: 'assets/animation/on_boarding4.json',
      title: "ابدأ رحلتك الآن",
      body:
      "لا تنتظر أكثر! انضم إلى آلاف المستخدمين الذين اختاروا تطبيقنا كأفضل شريك لحجز وإدارة المواعيد. مستقبل راحتك يبدأ هنا. اضغط على الزر وابدأ الآن!",
    ),
  ];

  final PageController boardingController = PageController();
  static const colorizeColors = [
    Colors.deepOrange,
    Colors.amber,
    Colors.yellow,
    Colors.red,
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: defaultBackgroundColor,
      body: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    itemCount: boarding.length,
                    controller: boardingController,
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: boardingController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (boardingController.hasClients && boardingController.page != null) {
                            value = boardingController.page! - index;
                            value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                          }
                          return Transform.scale(
                            scale: value,
                            child: AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 500),
                              child: SlideAnimation(
                                verticalOffset: 50.0, // Slide from the bottom
                                child: FadeInAnimation(
                                  child: ScaleAnimation(
                                    scale: 0.5, // Scale up from 50% to 100%
                                    child: buildOnBoandingItem(boarding[index]),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    onPageChanged: (index) {
                      if (index == boarding.length - 1) {
                        LoginCubit.get(context).chnageIsLast(true);
                      } else {
                        LoginCubit.get(context).chnageIsLast(false);
                      }
                    },
                  ),
                ),
                if (!LoginCubit.get(context).isLast)
                  AnimationConfiguration.staggeredList(
                    position: 0,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      verticalOffset: 50.0, // Slide from the bottom
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () async {
                                  boardingController.animateToPage(
                                    boarding.length - 1,
                                    duration: const Duration(milliseconds: 750),
                                    curve: Curves.fastEaseInToSlowEaseOut,
                                  );
                                },
                                child: const Text(
                                  "تخطي",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.deepOrangeAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              SmoothPageIndicator(
                                effect: const ExpandingDotsEffect(
                                  dotColor: Colors.grey,
                                  activeDotColor: Colors.deepOrangeAccent,
                                  dotHeight: 12,
                                  dotWidth: 12,
                                  expansionFactor: 4,
                                  spacing: 6.0,
                                ),
                                controller: boardingController,
                                count: boarding.length,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (LoginCubit.get(context).isLast)
                  AnimationConfiguration.staggeredList(
                    position: 0,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      verticalOffset: 50.0, // Slide from the bottom
                      child: FadeInAnimation(
                        child: buildElevatedButton(
                          onPressed: () async {
                            await CacheHelper.saveData(key: 'OnBoarding', value: true);
                            navigateTo(context, CustomerLayout());
                          },
                          width: 200,
                          child: const Text(
                            ' ابدأ الآن ',
                            style: TextStyle(
                              fontSize: 18,
                              // fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildOnBoandingItem(BoardingModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 90),
        Lottie.asset(model.image, height: 350),
        const SizedBox(height: 20),
        // Use ShimmerAnimatedText for the title
        AnimatedTextKit(
          animatedTexts: [
            ColorizeAnimatedText(
              model.title,
              textStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrangeAccent,
              ),
              textAlign: TextAlign.center,
              colors: colorizeColors,
            ),
          ],
          repeatForever: true, // Repeat the animation forever
        ),
        const SizedBox(height: 10),
        Text(
          model.body,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}