import 'dart:io';

import 'package:deviceguardianadmin/providers/login_provider.dart';
import 'package:deviceguardianadmin/util/dimensions.dart';
import 'package:deviceguardianadmin/util/post_login_navigation.dart';
import 'package:deviceguardianadmin/util/styles.dart';
import 'package:deviceguardianadmin/widgets/snack_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

enum _LocationIssue {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class ShopLocationScreen extends StatefulWidget {
  const ShopLocationScreen({super.key});

  @override
  State<ShopLocationScreen> createState() => _ShopLocationScreenState();
}

class _ShopLocationScreenState extends State<ShopLocationScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isFetchingLocation = true;
  bool _isSaving = false;
  String? _locationError;
  String? _locationErrorUrdu;
  _LocationIssue? _locationIssue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentLocation();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (_locationIssue != null || _currentPosition == null)) {
      _fetchCurrentLocation();
    }
  }

  LocationSettings _buildLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 20),
        forceLocationManager: true,
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 20),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 20),
    );
  }

  void _setLocationError({
    required _LocationIssue issue,
    required String message,
    required String messageUrdu,
  }) {
    setState(() {
      _locationIssue = issue;
      _locationError = message;
      _locationErrorUrdu = messageUrdu;
      _isFetchingLocation = false;
    });
  }

  Future<bool> _ensureLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setLocationError(
        issue: _LocationIssue.serviceDisabled,
        message:
            'Location is turned off on your device. Please turn on location/GPS first, then come back and tap Retry.',
        messageUrdu:
            'آپ کے فون میں لوکیشن بند ہے۔ براہ کرم پہلے لوکیشن/GPS آن کریں، پھر واپس آ کر دوبارہ کوشش کریں۔',
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _setLocationError(
        issue: _LocationIssue.permissionDenied,
        message:
            'Location permission is required. Please allow location access to set your shop location.',
        messageUrdu:
            'دکان کی لوکیشن سیٹ کرنے کے لیے لوکیشن کی اجازت درکار ہے۔ براہ کرم اجازت دیں۔',
      );
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _setLocationError(
        issue: _LocationIssue.permissionDeniedForever,
        message:
            'Location permission is blocked. Open app settings and allow location access.',
        messageUrdu:
            'لوکیشن کی اجازت بند ہے۔ ایپ سیٹنگز کھول کر لوکیشن کی اجازت دیں۔',
      );
      return false;
    }

    return true;
  }

  Future<Position?> _readCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _buildLocationSettings(),
      );
    } on LocationServiceDisabledException {
      rethrow;
    } on PermissionDeniedException {
      rethrow;
    } catch (e) {
      debugPrint('getCurrentPosition failed: $e');
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        debugPrint('Using last known position: $lastKnown');
        return lastKnown;
      }
      rethrow;
    }
  }

  Future<void> _fetchCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isFetchingLocation = true;
      _locationError = null;
      _locationErrorUrdu = null;
      _locationIssue = null;
    });

    try {
      if (!await _ensureLocationAccess()) {
        return;
      }

      final position = await _readCurrentPosition();
      if (position == null || !mounted) return;

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isFetchingLocation = false;
        _locationError = null;
        _locationErrorUrdu = null;
        _locationIssue = null;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 16),
      );
    } on LocationServiceDisabledException {
      if (!mounted) return;
      _setLocationError(
        issue: _LocationIssue.serviceDisabled,
        message:
            'Location is turned off on your device. Please turn on location/GPS first, then come back and tap Retry.',
        messageUrdu:
            'آپ کے فون میں لوکیشن بند ہے۔ براہ کرم پہلے لوکیشن/GPS آن کریں، پھر واپس آ کر دوبارہ کوشش کریں۔',
      );
    } on PermissionDeniedException {
      if (!mounted) return;
      _setLocationError(
        issue: _LocationIssue.permissionDenied,
        message:
            'Location permission is required. Please allow location access to set your shop location.',
        messageUrdu:
            'دکان کی لوکیشن سیٹ کرنے کے لیے لوکیشن کی اجازت درکار ہے۔ براہ کرم اجازت دیں۔',
      );
    } catch (e) {
      debugPrint('Failed to fetch current location: $e');
      if (!mounted) return;
      _setLocationError(
        issue: _LocationIssue.unavailable,
        message:
            'Unable to detect your current location. Make sure location is turned on and try again.',
        messageUrdu:
            'آپ کی موجودہ لوکیشن نہیں مل سکی۔ یقینی بنائیں کہ لوکیشن آن ہے اور دوبارہ کوشش کریں۔',
      );
    }
  }

  Future<void> _handleLocationAction() async {
    switch (_locationIssue) {
      case _LocationIssue.serviceDisabled:
        await Geolocator.openLocationSettings();
        break;
      case _LocationIssue.permissionDenied:
        await _fetchCurrentLocation();
        break;
      case _LocationIssue.permissionDeniedForever:
        await Geolocator.openAppSettings();
        break;
      case _LocationIssue.unavailable:
      case null:
        await _fetchCurrentLocation();
        break;
    }
  }

  String _primaryActionLabel() {
    switch (_locationIssue) {
      case _LocationIssue.serviceDisabled:
        return 'Turn On Location';
      case _LocationIssue.permissionDenied:
        return 'Allow Location Access';
      case _LocationIssue.permissionDeniedForever:
        return 'Open App Settings';
      case _LocationIssue.unavailable:
      case null:
        return 'Retry';
    }
  }

  Future<void> _handleSaveShopLocation() async {
    if (_currentPosition == null) {
      showCustomSnackBar(
        context,
        'Current location is not available yet.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<LoginProvider>();
    final success = await provider.storeUserLocation(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      showCustomSnackBar(
        context,
        'Shop location saved successfully!',
        isError: false,
      );
      await PostLoginNavigation.navigate(context);
    } else if (provider.errorMessage != null) {
      showCustomSnackBar(context, provider.errorMessage!, isError: true);
    }
  }

  Set<Marker> get _markers {
    if (_currentPosition == null) return {};

    return {
      Marker(
        markerId: const MarkerId('shop_location'),
        position: _currentPosition!,
        infoWindow: InfoWindow(
          title: 'Your Shop Location',
          snippet:
              '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
        ),
      ),
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initialPosition = _currentPosition ?? const LatLng(31.5204, 74.3587);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 15,
              ),
              markers: _markers,
              myLocationEnabled: _currentPosition != null,
              myLocationButtonEnabled: _currentPosition != null,
              zoomControlsEnabled: true,
              mapType: MapType.normal,
              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentPosition != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentPosition!, 16),
                  );
                }
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(
                        Dimensions.paddingSizeDefault,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusDefault,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set Shop Location',
                            style: robotoBold(context).copyWith(
                              fontSize: Dimensions.fontSizeLarge(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اپنی دکان کی لوکیشن سیٹ کریں',
                            style: robotoRegular(context).copyWith(
                              fontSize: Dimensions.fontSizeSmall(context),
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Turn on location, confirm your position on the map, then tap Save Shop Location.',
                            style: robotoRegular(context).copyWith(
                              fontSize: Dimensions.fontSizeSmall(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isFetchingLocation)
              Container(
                color: Colors.black.withValues(alpha: 0.2),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_locationError != null)
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _locationIssue == _LocationIssue.serviceDisabled
                            ? Icons.location_off_rounded
                            : Icons.location_disabled_rounded,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Text(
                        _locationError!,
                        textAlign: TextAlign.center,
                        style: robotoMedium(context),
                      ),
                      if (_locationErrorUrdu != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _locationErrorUrdu!,
                          textAlign: TextAlign.center,
                          style: robotoRegular(context).copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isFetchingLocation ? null : _handleLocationAction,
                          icon: Icon(
                            _locationIssue == _LocationIssue.serviceDisabled
                                ? Icons.gps_fixed
                                : Icons.settings,
                          ),
                          label: Text(_primaryActionLabel()),
                        ),
                      ),
                      if (_locationIssue != _LocationIssue.unavailable &&
                          _locationIssue != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed:
                              _isFetchingLocation ? null : _fetchCurrentLocation,
                          child: const Text('Retry'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isSaving ||
                              _isFetchingLocation ||
                              _currentPosition == null)
                          ? null
                          : _handleSaveShopLocation,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSizeDefault,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusDefault,
                          ),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Save Shop Location',
                              style: robotoBold(context).copyWith(
                                fontSize: Dimensions.fontSizeDefault(context),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
