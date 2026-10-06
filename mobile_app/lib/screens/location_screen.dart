import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../models/location.dart';
import '../services/device_service.dart';

class LocationScreen extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const LocationScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  LocationModel? _location;
  bool _isLoading = true;
  bool _isRequestingNewLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoading = true);
    try {
      final deviceService = context.read<DeviceService>();
      final loc = await deviceService.latestLocation(widget.deviceId);
      if (mounted) {
        setState(() {
          _location = loc;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestLocationUpdate() async {
    setState(() => _isRequestingNewLocation = true);
    try {
      final deviceService = context.read<DeviceService>();
      final res = await deviceService.sendCommand(widget.deviceId, 'LOCATION');
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location refresh command sent to laptop.'),
            backgroundColor: AppTheme.online,
          ),
        );
        // Wait a few seconds for laptop to scan Wi-Fi and update
        await Future.delayed(const Duration(seconds: 4));
        if (mounted) _fetchLocation();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] as String? ?? 'Failed to request location'),
            backgroundColor: AppTheme.offline,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequestingNewLocation = false);
    }
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch maps URL.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = _location;
    final timeStr = loc?.createdAt != null
        ? DateFormat('h:mm a, MMM d, yyyy').format(loc!.createdAt!)
        : 'Unknown';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Device Location'),
            Text(
              widget.deviceName,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchLocation,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              onRefresh: _fetchLocation,
              color: AppTheme.accent,
              backgroundColor: AppTheme.bgElevated,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Location Map Preview / Coordinates Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.pin_drop_rounded,
                                color: AppTheme.accent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc?.fullAddress ?? 'Location Unavailable',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Updated $timeStr',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (loc != null && loc.hasCoordinates) ...[
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _coordCol('LATITUDE', '${loc.latitude.toStringAsFixed(5)}°'),
                              _coordCol('LONGITUDE', '${loc.longitude.toStringAsFixed(5)}°'),
                              if (loc.accuracyMeters != null)
                                _coordCol('ACCURACY', '±${loc.accuracyMeters!.round()}m'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: Colors.black,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            icon: const Icon(Icons.map_rounded, size: 20),
                            label: const Text('Open in Google Maps'),
                            onPressed: () => _openGoogleMaps(loc.latitude, loc.longitude),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Metadata Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detection Source',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _infoRow('Method', loc?.source ?? 'IP Geolocation / Wi-Fi Triangulation'),
                        _infoRow('City', loc?.city ?? 'Unknown'),
                        _infoRow('State / Region', loc?.region ?? 'Unknown'),
                        _infoRow('Country', loc?.country ?? 'Unknown'),
                        _infoRow('ISP / Carrier', loc?.isp ?? 'Unknown', isLast: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Request Instant Update Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      side: const BorderSide(color: AppTheme.accent),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: _isRequestingNewLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.accent,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded, size: 20),
                    label: const Text('Request Fresh Location from Laptop'),
                    onPressed: _isRequestingNewLocation ? null : _requestLocationUpdate,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _coordCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
