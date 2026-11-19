import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

class LocationPickerDialog extends StatefulWidget {
  final String initialAddress;

  const LocationPickerDialog({
    super.key,
    this.initialAddress = 'Naval, Biliran, Philippines',
  });

  static Future<String?> show(BuildContext context, {String initialAddress = ''}) {
    return showDialog<String>(
      context: context,
      builder: (_) => LocationPickerDialog(
        initialAddress: initialAddress.isNotEmpty
            ? initialAddress
            : 'Naval, Biliran, Philippines',
      ),
    );
  }

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late TextEditingController _addressCtrl;
  late final MapController _mapController;

  // Real device GPS position
  LatLng _selectedPoint = const LatLng(11.5606, 124.3986);
  double _currentZoom = 15.0;
  double _currentRotation = 0.0;
  bool _isLoadingGps = false;

  final List<Map<String, dynamic>> _popularLocations = [
    {
      'name': 'Naval Center',
      'full': 'Naval, Biliran, Philippines',
      'lat': 11.5606,
      'lng': 124.3986,
    },
    {
      'name': 'Brgy. Smo. Rosario',
      'full': 'Brgy. Smo. Rosario, Naval, Biliran, Philippines',
      'lat': 11.5615,
      'lng': 124.3975,
    },
    {
      'name': 'Brgy. P.I. Garcia',
      'full': 'Brgy. P.I. Garcia, Naval, Biliran, Philippines',
      'lat': 11.5640,
      'lng': 124.3960,
    },
    {
      'name': 'Brgy. Atipolo',
      'full': 'Brgy. Atipolo, Naval, Biliran, Philippines',
      'lat': 11.5580,
      'lng': 124.4020,
    },
    {
      'name': 'Brgy. Agpangi',
      'full': 'Brgy. Agpangi, Naval, Biliran, Philippines',
      'lat': 11.5720,
      'lng': 124.3910,
    },
    {
      'name': 'Brgy. Calumpang',
      'full': 'Brgy. Calumpang, Naval, Biliran, Philippines',
      'lat': 11.5510,
      'lng': 124.3940,
    },
    {
      'name': 'Brgy. Caraycaray',
      'full': 'Brgy. Caraycaray, Naval, Biliran, Philippines',
      'lat': 11.5530,
      'lng': 124.4080,
    },
    {
      'name': 'BiPSU Main Campus',
      'full': 'BiPSU Main Campus, Naval, Biliran, Philippines',
      'lat': 11.5660,
      'lng': 124.4005,
    },
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _addressCtrl = TextEditingController(
      text: widget.initialAddress.isNotEmpty
          ? widget.initialAddress
          : 'Naval, Biliran, Philippines',
    );
    _initDeviceLocation();
  }

  Future<void> _initDeviceLocation() async {
    final realLoc = await LocationService().getCurrentDeviceLocation();
    if (mounted) {
      setState(() {
        _selectedPoint = realLoc;
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Automatic address resolver on pin placement
  void _updateAddressFromPoint(LatLng point, {String? customLabel}) {
    String resolvedAddress = customLabel ?? '';
    const distanceThreshold = 0.008; // ~800m radius

    if (resolvedAddress.isEmpty) {
      for (final loc in _popularLocations) {
        final double lat = loc['lat'] as double;
        final double lng = loc['lng'] as double;
        final double diff = (lat - point.latitude).abs() + (lng - point.longitude).abs();
        if (diff < distanceThreshold) {
          resolvedAddress = loc['full'] as String;
          break;
        }
      }
    }

    if (resolvedAddress.isEmpty) {
      resolvedAddress =
          'Naval, Biliran, Philippines (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
    }

    setState(() {
      _selectedPoint = point;
      _addressCtrl.text = resolvedAddress;
    });
  }

  Future<void> _goToMyLocation() async {
    setState(() {
      _isLoadingGps = true;
    });

    final realLoc = await LocationService().getCurrentDeviceLocation();

    if (mounted) {
      _updateAddressFromPoint(
        realLoc,
        customLabel:
            'My Device GPS Location (${realLoc.latitude.toStringAsFixed(4)}, ${realLoc.longitude.toStringAsFixed(4)})',
      );
      setState(() {
        _currentZoom = 16.0;
        _isLoadingGps = false;
      });
      _mapController.move(realLoc, 16.0);
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(3.0, 18.0);
      _mapController.move(_selectedPoint, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(3.0, 18.0);
      _mapController.move(_selectedPoint, _currentZoom);
    });
  }

  void _resetRecenter() {
    setState(() {
      _currentZoom = 15.0;
      _selectedPoint = const LatLng(11.5606, 124.3986);
      _addressCtrl.text = 'Naval, Biliran, Philippines';
      _mapController.move(_selectedPoint, _currentZoom);
      _mapController.rotate(0.0);
      _currentRotation = 0.0;
    });
  }

  void _resetRotation() {
    setState(() {
      _mapController.rotate(0.0);
      _currentRotation = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: maroonColor,
                child: const Row(
                  children: [
                    Icon(Icons.public, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Select Real Device GPS Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // OpenStreetMap Map Layer with Real Device GPS & Gestures
              Container(
                height: 270,
                color: const Color(0xFFEFEBE7),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedPoint,
                        initialZoom: _currentZoom,
                        initialRotation: 0.0,
                        minZoom: 3.0,
                        maxZoom: 18.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                        onPositionChanged: (position, hasGesture) {
                          if (hasGesture) {
                            setState(() {
                              if (position.zoom != null) _currentZoom = position.zoom!;
                              _currentRotation = position.rotation;
                            });
                          }
                        },
                        onTap: (tapPosition, point) {
                          _updateAddressFromPoint(point);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.hanapgawa.app',
                          tileProvider: CancellableNetworkTileProvider(),
                        ),
                        MarkerLayer(
                          markers: [
                            // PINNED TARGET LOCATION MARKER
                            Marker(
                              point: _selectedPoint,
                              width: 90,
                              height: 65,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: maroonColor,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black26, blurRadius: 4),
                                      ],
                                    ),
                                    child: const Text(
                                      'Pinned Target',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.location_on,
                                    color: maroonColor,
                                    size: 38,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Instruction Overlay Banner
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(235),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.gps_fixed, size: 16, color: maroonColor),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Tap blue GPS button to use your live device location!',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: maroonColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Floating Controls Column (GPS My Location, Rotation Compass, Zoom +, Zoom -, Reset)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // My Current Device Real GPS Button
                          Material(
                            color: Colors.blue[800],
                            shape: const CircleBorder(),
                            elevation: 5,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _goToMyLocation,
                              child: Padding(
                                padding: const EdgeInsets.all(7.0),
                                child: _isLoadingGps
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.my_location,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Compass Rotation Reset Button
                          Transform.rotate(
                            angle: -_currentRotation * (3.141592653589793 / 180),
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 4,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _resetRotation,
                                child: const Padding(
                                  padding: EdgeInsets.all(7.0),
                                  child: Icon(Icons.navigation, color: maroonColor, size: 18),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Zoom In (+) Button
                          Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _zoomIn,
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(Icons.add, color: maroonColor, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Zoom Scale Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: maroonColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Z${_currentZoom.toInt()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Zoom Out (-) Button
                          Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _zoomOut,
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(Icons.remove, color: maroonColor, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Recenter Button
                          Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _resetRecenter,
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(Icons.center_focus_strong, color: maroonColor, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Popular Location Presets for Naval, Biliran
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Naval, Biliran Location Presets:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: maroonColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _popularLocations.map((loc) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(
                                loc['name'] as String,
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: maroonColor.withAlpha(20),
                              labelStyle: const TextStyle(color: maroonColor),
                              onPressed: () {
                                final point = LatLng(
                                  loc['lat'] as double,
                                  loc['lng'] as double,
                                );
                                _updateAddressFromPoint(point);
                                _mapController.move(point, 15.5);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Selected Address TextFormField (Auto-updated on pin tap or My Location!)
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pinned Address / Location (Auto-filled)',
                        prefixIcon: Icon(Icons.pin_drop, color: maroonColor),
                        border: OutlineInputBorder(),
                        helperText: 'Auto-updates when you tap map or blue GPS button',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: maroonColor,
                          ),
                          onPressed: () {
                            Navigator.pop(context, _addressCtrl.text.trim());
                          },
                          icon: const Icon(Icons.check, color: Colors.white, size: 18),
                          label: const Text(
                            'CONFIRM LOCATION',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
