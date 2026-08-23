import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/booking_model/booking_model.dart';

class ServiceProviderReportsScreen extends StatelessWidget {
  final String serviceProviderId; // Unique ID for the service provider

  const ServiceProviderReportsScreen({
    required this.serviceProviderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<BookingModel>>(
        future: _fetchBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد حجوزات.'));
          }

          final allBookings = snapshot.data!;
          return _buildReportTabs(allBookings);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Optionally, add refresh or other actions here
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Future<List<BookingModel>> _fetchBookings() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: serviceProviderId)
        .get();

    return querySnapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
  }

  Widget _buildReportTabs(List<BookingModel> allBookings) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10.0,
                  spreadRadius: 5.0,
                ),
              ],
            ),
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.blueAccent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                color: Colors.blueAccent,
              ),
              tabs: const [
                Tab(text: 'أسبوعي'),
                Tab(text: 'شهري'),
                Tab(text: 'سنوي'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildChart(allBookings, 'weekly'),
                _buildChart(allBookings, 'monthly'),
                _buildChart(allBookings, 'yearly'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<BookingModel> _filterBookingsByPeriod(List<BookingModel> allBookings, String period) {
    final now = DateTime.now();
    DateTime startOfPeriod;

    if (period == 'weekly') {
      startOfPeriod = now.subtract(Duration(days: now.weekday)); // Start from Sunday
    } else if (period == 'monthly') {
      startOfPeriod = DateTime(now.year, now.month, 1); // First day of the current month
    } else if (period == 'yearly') {
      startOfPeriod = DateTime(now.year, 1, 1); // First day of the current year
    } else {
      return []; // Default return empty if invalid period is passed
    }

    return allBookings.where((booking) {
      final bookingDate = booking.timestamp.toDate();
      if (period == 'weekly') {
        return bookingDate.isAfter(startOfPeriod);
      } else if (period == 'monthly') {
        final endOfMonth = DateTime(now.year, now.month + 1, 0); // Last day of the current month
        return bookingDate.isAfter(startOfPeriod) && bookingDate.isBefore(endOfMonth);
      } else if (period == 'yearly') {
        final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
        return bookingDate.isAfter(startOfPeriod) && bookingDate.isBefore(endOfYear);
      }
      return false;
    }).toList();
  }

  int _getPreviousPeriodCount(List<BookingModel> allBookings, String period) {
    final now = DateTime.now();
    DateTime startOfPreviousPeriod;
    DateTime endOfPreviousPeriod;

    if (period == 'weekly') {
      startOfPreviousPeriod = now.subtract(Duration(days: now.weekday + 7)); // Last week's start
      endOfPreviousPeriod = now.subtract(Duration(days: now.weekday)); // Last week's end
    } else if (period == 'monthly') {
      startOfPreviousPeriod = DateTime(now.year, now.month - 1, 1); // Last month's start
      endOfPreviousPeriod = DateTime(now.year, now.month, 0); // Last month's end
    } else if (period == 'yearly') {
      startOfPreviousPeriod = DateTime(now.year - 1, 1, 1); // Last year's start
      endOfPreviousPeriod = DateTime(now.year - 1, 12, 31); // Last year's end
    } else {
      return 0;
    }

    return allBookings.where((booking) {
      final bookingDate = booking.timestamp.toDate();
      return bookingDate.isAfter(startOfPreviousPeriod) && bookingDate.isBefore(endOfPreviousPeriod);
    }).length;
  }

  Widget _buildChart(List<BookingModel> allBookings, String period) {
    final filteredBookings = _filterBookingsByPeriod(allBookings, period);
    final previousPeriodCount = _getPreviousPeriodCount(allBookings, period);
    final currentPeriodCount = filteredBookings.length;

    final comparisonMessage = currentPeriodCount > previousPeriodCount
        ? 'لديك حجوزات أكثر من $period الماضي!'
        : (currentPeriodCount < previousPeriodCount
        ? 'لديك حجوزات أقل من $period الماضي.'
        : 'لديك نفس عدد الحجوزات كما في $period الماضي.');

    final bookingDifference = currentPeriodCount - previousPeriodCount;

    final groupedData = <String, int>{};
    for (var booking in filteredBookings) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(booking.timestamp.toDate());
      groupedData[formattedDate] = (groupedData[formattedDate] ?? 0) + 1;
    }

    final chartData = groupedData.entries
        .map((entry) => ChartData(entry.key, entry.value))
        .toList();

    // Determine the color for the chart based on the comparison
    Color chartColor = Colors.blueAccent;  // Default color (equal bookings)
    if (currentPeriodCount > previousPeriodCount) {
      chartColor = Colors.green;  // More bookings
    } else if (currentPeriodCount < previousPeriodCount) {
      chartColor = Colors.red;  // Less bookings
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Comparison message
          Text(
            comparisonMessage,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: currentPeriodCount > previousPeriodCount
                  ? Colors.green
                  : (currentPeriodCount < previousPeriodCount ? Colors.red : Colors.blue),
            ),
          ),
          // Display the difference in bookings
          SizedBox(height: 10),
          Text(
            'الفرق: ${bookingDifference >= 0 ? '+' : ''}$bookingDifference حجوزات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: bookingDifference >= 0 ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(height: 30),  // Added larger spacing before the chart
          Expanded(
            child: SfCartesianChart(
              title: ChartTitle(
                text: '$period الحجوزات',
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              primaryXAxis: CategoryAxis(
                labelRotation: 45,
                title: AxisTitle(
                  text: 'التاريخ',
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(
                  text: 'عدد الحجوزات',
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                header: '',
                canShowMarker: false,
                color: Colors.blueAccent,
              ),
              series: <CartesianSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.date,
                  yValueMapper: (ChartData data, _) => data.count,
                  name: 'حجوزات',
                  color: chartColor,  // Apply the dynamic color here
                  borderRadius: BorderRadius.circular(10),
                  dataLabelSettings: DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String date;
  final int count;

  ChartData(this.date, this.count);
}