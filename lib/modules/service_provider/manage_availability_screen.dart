import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:service_booking_app/shared/styles/colors.dart';
import '../../cubits/availability_cubit/availability_cubit.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../cubits/availability_cubit/availability_cubit.dart';
import '../../shared/components/components.dart';

class AvailabilityScreen extends StatelessWidget {
  final String providerId;

  const AvailabilityScreen({Key? key, required this.providerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AvailabilityCubit(providerId: providerId)..listenToAvailability(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          // backgroundColor: defaultBackgroundColor,
          // appBar: AppBar(
          //   title: const Text('إدارة التوفر'),
          //   backgroundColor: Colors.white,
          //   leading: IconButton(
          //     icon: CircleAvatar(
          //       backgroundColor: Colors.red[50],
          //       child: const Icon(
          //         Icons.arrow_back,
          //         color: Colors.red,
          //       ),
          //     ),
          //     onPressed: () {
          //       Navigator.pop(context);
          //     },
          //   ),
          // ),
          body: SingleChildScrollView(
            child: BlocBuilder<AvailabilityCubit, AvailabilityState>(
              builder: (context, state) {
                if (state is AvailabilityLoading) {
                  return buildSpinKitFadingCircle();
                } else if (state is AvailabilityLoaded) {
                  return _buildDayGrid(context, state.availability);
                } else if (state is AvailabilityError) {
                  return Center(
                    child: Text(
                      'خطأ: ${state.message}',
                      style: const TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  );
                }
                return const Center(
                  child: Text(
                    'لا توجد بيانات توفّر.',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayGrid(BuildContext context, Map<String, dynamic> availability) {
    final days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.80,
        ),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final times = availability[day] ?? {'startTime': 'لم يتم تعيينه', 'endTime': 'لم يتم تعيينه'};
          final isDayOff = availability[day]?['dayIsOff'] ?? false;

          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 500),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageDayAvailabilityScreen(
                          providerId: providerId,
                          day: day,
                          startTime: times['startTime'],
                          endTime: times['endTime'],
                          isDayOff: isDayOff,
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: isDayOff ? Colors.red[50] : Colors.green[50],
                        ),
                        child: Stack(
                          children: [
                            // Calendar icon at the top
                            Positioned(
                              top: 8,
                              left: 0,
                              right: 0,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: CircleAvatar(
                                  backgroundColor: isDayOff ? Colors.red[100] : Colors.green[100],
                                  radius: 35,
                                  child: Icon(
                                    isDayOff ? Icons.event_busy : Icons.event,
                                    color: isDayOff ? Colors.red : Colors.green,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                            // Center content (day and time)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        day.toUpperCase(),
                                        style: TextStyle(
                                          color: isDayOff ? Colors.red : Colors.green[900],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Flexible(
                                      child: Text(
                                        isDayOff
                                            ? 'غير متاح '
                                            : '${times['startTime']} - ${times['endTime']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDayOff ? Colors.red : Colors.green[800],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Bottom button
                            Positioned(
                              bottom: 8,
                              left: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDayOff ? Colors.red : Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  isDayOff ? 'إنقر لتعديل' : 'إنقر لتعديل',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}










/////////////////////////////////////////////////////////////










class ManageDayAvailabilityScreen extends StatefulWidget {
  final String providerId;
  final String day;
  final String startTime;
  final String endTime;
  final bool isDayOff;

  const ManageDayAvailabilityScreen({
    Key? key,
    required this.providerId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.isDayOff,
  }) : super(key: key);

  @override
  _ManageDayAvailabilityScreenState createState() => _ManageDayAvailabilityScreenState();
}

class _ManageDayAvailabilityScreenState extends State<ManageDayAvailabilityScreen> {
  late TextEditingController startTimeController;
  late TextEditingController endTimeController;
  late bool _isDayOff;

  @override
  void initState() {
    super.initState();
    startTimeController = TextEditingController(text: widget.startTime);
    endTimeController = TextEditingController(text: widget.endTime);
    _isDayOff = widget.isDayOff;
  }

  @override
  void dispose() {
    startTimeController.dispose();
    endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<AvailabilityCubit>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text('إدارة ${widget.day}'),
            backgroundColor: Colors.white,
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
          ),
          body: BlocConsumer<AvailabilityCubit, AvailabilityState>(
            listener: (context, state) {
              if (state is AvailabilitySuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.green),
                );
                Navigator.pop(context);
              } else if (state is AvailabilityError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
              }
            },
            builder: (context, state) {
              if (state is AvailabilitySaving) {
                return buildSpinKitFadingCircle();
              }
        
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تعيين التوفر',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    // Start Time Picker
                    TextField(
                      controller: startTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'وقت البدء (مثال: 7:00 صباحاً)',
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final time = await _selectTime(context, startTimeController.text);
                        if (time != null) {
                          startTimeController.text = time;
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    // End Time Picker
                    TextField(
                      controller: endTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'وقت الانتهاء (مثال: 10:00 مساءً)',
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final time = await _selectTime(context, endTimeController.text);
                        if (time != null) {
                          endTimeController.text = time;
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    // Day Off Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'يوم عطلة',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: _isDayOff,
                          onChanged: (value) {
                            setState(() {
                              _isDayOff = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final startTime = startTimeController.text;
                          final endTime = endTimeController.text;
                          context.read<AvailabilityCubit>().saveDayAvailability(
                              widget.day, startTime, endTime, _isDayOff);
                        },
                        child: const Text('حفظ'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<String?> _selectTime(BuildContext context, String initialTime) async {
    TimeOfDay? initialTimeOfDay;
    if (initialTime.isNotEmpty) {
      try {
        final parsedTime = TimeOfDay(
          hour: int.parse(initialTime.split(":")[0]),
          minute: int.parse(initialTime.split(":")[1].split(" ")[0]),
        );
        initialTimeOfDay = parsedTime;
      } catch (_) {
        initialTimeOfDay = TimeOfDay.now();
      }
    } else {
      initialTimeOfDay = TimeOfDay.now();
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTimeOfDay,
    );

    if (pickedTime != null) {
      final hour = pickedTime.hour > 12 ? pickedTime.hour - 12 : pickedTime.hour;
      final minute = pickedTime.minute.toString().padLeft(2, '0');
      final period = pickedTime.period == DayPeriod.am ? 'ص' : 'م';
      return '$hour:$minute $period';
    }
    return null;
  }
}