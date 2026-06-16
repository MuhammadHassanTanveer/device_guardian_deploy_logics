import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeviceLocationMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const DeviceLocationMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<DeviceLocationMapWidget> createState() =>
      _DeviceLocationMapWidgetState();
}

class _DeviceLocationMapWidgetState extends State<DeviceLocationMapWidget> {
  GoogleMapController? _mapController;

  LatLng get _position => LatLng(widget.latitude, widget.longitude);

  Set<Marker> get _markers => {
        Marker(
          markerId: const MarkerId('device_location'),
          position: _position,
          infoWindow: InfoWindow(
            title: 'Device Location',
            snippet:
                '${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
          ),
        ),
      };

  @override
  void didUpdateWidget(covariant DeviceLocationMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _moveCameraToLocation();
    }
  }

  Future<void> _moveCameraToLocation() async {
    final controller = _mapController;
    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(_position, 15),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _position,
            zoom: 15,
          ),
          markers: _markers,
          mapType: MapType.normal,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),
      ),
    );
  }
}
