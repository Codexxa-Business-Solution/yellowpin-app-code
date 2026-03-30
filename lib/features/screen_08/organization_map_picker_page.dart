import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/services/google_geocoding_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_primary_button.dart';

/// Full-screen map: pan to choose point, search, current location, confirm address.
class OrganizationLocationMapResult {
  const OrganizationLocationMapResult({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.pinCode,
  });

  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String pinCode;
}

class OrganizationMapPickerPage extends StatefulWidget {
  const OrganizationMapPickerPage({super.key});

  @override
  State<OrganizationMapPickerPage> createState() => _OrganizationMapPickerPageState();
}

class _OrganizationMapPickerPageState extends State<OrganizationMapPickerPage> {
  final _geo = GoogleGeocodingService();
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(18.5204, 73.8567); // Pune default
  bool _loadingAddress = false;
  String _title = '';
  String _subtitle = '';
  bool _searching = false;
  Timer? _idleDebounce;

  @override
  void dispose() {
    _idleDebounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng target) async {
    setState(() => _loadingAddress = true);
    final r = await _geo.reverseGeocode(target.latitude, target.longitude);
    if (!mounted) return;
    setState(() {
      _loadingAddress = false;
      if (r != null) {
        _center = LatLng(r.latitude, r.longitude);
        final parts = r.formattedAddress.split(',');
        _title = parts.isNotEmpty ? parts.first.trim() : 'Selected location';
        _subtitle = r.formattedAddress;
      } else {
        _title = 'Selected location';
        _subtitle = '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
      }
    });
  }

  Future<void> _onSearch() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    final r = await _geo.forwardGeocode(q);
    if (!mounted) return;
    setState(() => _searching = false);
    if (r == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No results found'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    _center = LatLng(r.latitude, r.longitude);
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 16));
    await _reverseGeocode(_center);
  }

  Future<void> _useCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turn on location services'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    _center = LatLng(pos.latitude, pos.longitude);
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 16));
    await _reverseGeocode(_center);
  }

  void _confirm() async {
    final r = await _geo.reverseGeocode(_center.latitude, _center.longitude);
    if (!mounted) return;
    if (r == null) {
      Navigator.pop(
        context,
        OrganizationLocationMapResult(
          formattedAddress: _subtitle,
          latitude: _center.latitude,
          longitude: _center.longitude,
          city: '',
          state: '',
          pinCode: '',
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      OrganizationLocationMapResult(
        formattedAddress: r.formattedAddress,
        latitude: r.latitude,
        longitude: r.longitude,
        city: r.city,
        state: r.state,
        pinCode: r.pinCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerYellow,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 14),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) {
              _mapController = c;
              _reverseGeocode(_center);
            },
            onCameraMove: (pos) => _center = pos.target,
            onCameraIdle: () {
              _idleDebounce?.cancel();
              _idleDebounce = Timer(const Duration(milliseconds: 700), () {
                if (mounted) _reverseGeocode(_center);
              });
            },
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_pin, size: 48, color: Color(0xFFE53935)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(backgroundColor: AppColors.white),
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _onSearch(),
                      decoration: InputDecoration(
                        hintText: 'Search location',
                        prefixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : const Icon(Icons.search, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: _useCurrentLocation,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.my_location, color: AppColors.textPrimary, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Current location', style: AppTextStyles.bodyMedium(context)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.lg,
                    AppSpacing.screenHorizontal,
                    AppSpacing.xl,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, -4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_loadingAddress)
                        const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                      else ...[
                        Text(
                          _title.isEmpty ? 'Move map to adjust pin' : _title,
                          style: AppTextStyles.headingMedium(context).copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _subtitle,
                          style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppPrimaryButton(
                        label: 'Confirm & Proceed',
                        onPressed: _loadingAddress ? null : _confirm,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
