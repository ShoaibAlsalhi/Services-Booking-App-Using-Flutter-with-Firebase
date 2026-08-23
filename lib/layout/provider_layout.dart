import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart'; // Import the package
import '../cubits/service_provider_cubit/manage_booking/manage_booking_cubit.dart';
import '../cubits/service_provider_cubit/provider_layout_cubit/provider_layout_cubit.dart';
import '../cubits/service_provider_cubit/provider_layout_cubit/provider_layout_state.dart';
import '../modules/logout/logoutscreen.dart';
import '../modules/service_provider/manage_availability_screen.dart';
import '../modules/service_provider/manage_booking_screen/manage_booking_screen.dart';
import '../shared/components/components.dart';

class ProviderLayout extends StatelessWidget {
  final String providerId;

  const ProviderLayout({Key? key, required this.providerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ProviderLayoutCubit()..getUnseenBookingsCount()),
      ],
      child: BlocConsumer<ProviderLayoutCubit, ProviderLayoutStates>(
        listener: (BuildContext context, ProviderLayoutStates state) {},
        builder: (BuildContext context, ProviderLayoutStates state) {
          ProviderLayoutCubit cubit = ProviderLayoutCubit.get(context);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              key: _scaffoldKey,
              appBar: AppBar(
                title: Text(cubit.providerScreensTitles[cubit.providerCurrentIndex]),
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
              ),
              drawer: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const DrawerHeader(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                      ),
                      child: Text(
                        "Menu",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: const Text("Manage Availability Time"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AvailabilityScreen(providerId: providerId),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text("Settings"),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.contact_page),
                      title: const Text("Contact Us"),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              body: cubit.providerScreens[cubit.providerCurrentIndex],
              bottomNavigationBar: BlocBuilder<ProviderLayoutCubit, ProviderLayoutStates>(
                builder: (context, state) {
                  int unseenBookingsCount = cubit.unseenBookingsCount;

                  return CurvedNavigationBar(
                    index: cubit.providerCurrentIndex,
                    height: 60.0,
                    items: <Widget>[
                      Icon(
                        Icons.home,
                        size: 30,
                        color: cubit.providerCurrentIndex == 0 ? Colors.deepOrange : Colors.black,
                      ),
                      Icon(
                        Icons.bar_chart,
                        size: 30,
                        color: cubit.providerCurrentIndex == 1 ? Colors.deepOrange : Colors.black,
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.book_online,
                            size: 30,
                            color: cubit.providerCurrentIndex == 2 ? Colors.deepOrange : Colors.black,
                          ),
                          if (unseenBookingsCount > 0)
                            Positioned(
                              right: -5,
                              top: -46,
                              child: CustomPaint(
                                size: const Size(72, 48),
                                painter: SpeechBubblePainter(color: Colors.red),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.book_online, color: Colors.white, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        unseenBookingsCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Icon(
                        Icons.reviews,
                        size: 30,
                        color: cubit.providerCurrentIndex == 3 ? Colors.deepOrange : Colors.black,
                      ),
                      Icon(
                        Icons.person,
                        size: 30,
                        color: cubit.providerCurrentIndex == 4 ? Colors.deepOrange : Colors.black,
                      ),
                      Icon(
                        Icons.timer_outlined,
                        size: 30,
                        color: cubit.providerCurrentIndex == 5 ? Colors.deepOrange : Colors.black,
                      ),
                    ],
                    color: Colors.white, // Background color of the navigation bar
                    buttonBackgroundColor: Colors.orange[50], // Color of the selected icon's button
                    backgroundColor: Colors.grey.shade200, // Background color of the bar
                    animationDuration: Duration(milliseconds: 300),
                    onTap: (index) {
                      cubit.changeIndex(index);
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class SpeechBubblePainter extends CustomPainter {
  final Color color;

  SpeechBubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path();

    // Create the rounded speech bubble
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(5), // Rounded corners
    ));

    // Add the tail (triangle) - Smaller tail
    path.moveTo(size.width / 2 - 8, size.height); // Tail width
    path.lineTo(size.width / 2, size.height + 12); // Tail height
    path.lineTo(size.width / 2 + 8, size.height); // Tail width
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}