class AvailabilityModel {
  final String day;
  final String startTime;
  final String endTime;
  final bool dayIsOff;  // Added field to indicate if the day is off

  AvailabilityModel({
    required this.day,
    required this.startTime,
    required this.endTime,
    this.dayIsOff = false,  // Default to false, meaning the day is not off
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'dayIsOff': dayIsOff,  // Include dayIsOff in the map
    };
  }

  factory AvailabilityModel.fromMap(String day, Map<String, dynamic> data) {
    return AvailabilityModel(
      day: day,
      startTime: data['startTime'] ?? 'N/A',
      endTime: data['endTime'] ?? 'N/A',
      dayIsOff: data['dayIsOff'] ?? false,  // Default to false if not provided
    );
  }
}
