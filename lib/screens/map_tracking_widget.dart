// lib/screens/map_tracking_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapTrackingWidget extends StatefulWidget {
  const MapTrackingWidget({super.key});

  @override
  _MapTrackingWidgetState createState() => _MapTrackingWidgetState();
}

class _MapTrackingWidgetState extends State<MapTrackingWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng _initialPosition = LatLng(4.2105, 101.9758); // fallback: Malaysia
  Marker? _userMarker;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) return;

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _initialPosition = LatLng(position.latitude, position.longitude);

    _userMarker = Marker(
      markerId: MarkerId('current_location'),
      position: _initialPosition,
      infoWindow: InfoWindow(title: 'Anda di sini'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition, 16));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      margin: EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 14),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          onMapCreated: (controller) => _controller.complete(controller),
          markers: _userMarker != null ? {_userMarker!} : {},
        ),
      ),
    );
  }
}
