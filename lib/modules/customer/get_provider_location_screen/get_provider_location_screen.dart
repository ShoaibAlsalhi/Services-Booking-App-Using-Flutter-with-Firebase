import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/components/components.dart';

class ProviderLocationScreen extends StatefulWidget {
  final double providerLatitude;
  final double providerLongitude;
  final String providerName;

  const ProviderLocationScreen({
    Key? key,
    required this.providerLatitude,
    required this.providerLongitude,
    required this.providerName,
  }) : super(key: key);

  @override
  _ProviderLocationScreenState createState() => _ProviderLocationScreenState();
}

class _ProviderLocationScreenState extends State<ProviderLocationScreen>
    with WidgetsBindingObserver {
  LatLng? _userLatLng;
  bool _openedGoogleMaps = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _openedGoogleMaps) {
      // When the app resumes, go back to the previous screen
      Navigator.pop(context);
    }
  }

  Future<void> _fetchUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    // If location service is not enabled, prompt the user to enable it
    if (!serviceEnabled) {
      bool locationEnabled = await _enableLocationService();
      if (!locationEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب تفعيل خدمة الموقع للمتابعة.')),
        );
        return;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض أذونات الموقع.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض أذونات الموقع بشكل دائم.')),
      );
      return;
    }

    try {
      Position userPosition = await Geolocator.getCurrentPosition();
      setState(() {
        _userLatLng = LatLng(userPosition.latitude, userPosition.longitude);
      });

      // Open Google Maps automatically
      _openGoogleMapsDirections();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء جلب الموقع: $e')),
      );
    }
  }

  Future<bool> _enableLocationService() async {
    // Open the location settings
    bool serviceEnabled = await Geolocator.openLocationSettings();

    // Check if the location service is enabled after opening settings
    if (serviceEnabled) {
      return true;
    } else {
      return false;
    }
  }
  Future<void> _openGoogleMapsDirections() async {
    if (_userLatLng == null) return;

    final url =
        "https://www.google.com/maps/dir/?api=1&origin=${_userLatLng!.latitude},${_userLatLng!.longitude}&destination=${widget.providerLatitude},${widget.providerLongitude}&travelmode=driving";

    if (await canLaunchUrl(Uri.parse(url))) {
      _openedGoogleMaps = true;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح خرائط Google')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('موقع المزود')),
      body: Center(
        child: _userLatLng == null
            ?  buildSpinKitFadingCircle()
            : const Text(
          'جارٍ فتح خرائط Google...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}