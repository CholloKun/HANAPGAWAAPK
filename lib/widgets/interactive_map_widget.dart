import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../models/app_models.dart';
import '../screens/job_detail_screen.dart';
import '../services/location_service.dart';

class InteractiveMapWidget extends StatefulWidget {
  final List<JobBooking> jobs;
  final List<WorkerModel> workers;
  final JobBooking? selectedJob;
  final Function(JobBooking)? onJobSelected;
  final double height;

  const InteractiveMapWidget({
    super.key,
    required this.jobs,
    required this.workers,
    this.selectedJob,
    this.onJobSelected,
    this.height = 360,
  });

  @override
  State<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends State<InteractiveMapWidget> {
  late final MapController _mapController;
  JobBooking? _activeJob;
  double _currentZoom = 14.5;
  double _currentRotation = 0.0;

  // Real GPS Location state
  LatLng _userGpsLocation = const LatLng(11.5606, 124.3986);
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _activeJob = widget.selectedJob ?? (widget.jobs.isNotEmpty ? widget.jobs.first : null);
    _fetchRealDeviceLocation();
  }

  Future<void> _fetchRealDeviceLocation() async {
    final realLoc = await LocationService().getCurrentDeviceLocation();
    if (mounted) {
      setState(() {
        _userGpsLocation = realLoc;
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(3.0, 18.0);
      final center = _mapController.camera.center;
      _mapController.move(center, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(3.0, 18.0);
      final center = _mapController.camera.center;
      _mapController.move(center, _currentZoom);
    });
  }

  void _resetRecenter() {
    setState(() {
      _currentZoom = 14.5;
      _mapController.move(_userGpsLocation, _currentZoom);
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

  void _rotateLeft() {
    setState(() {
      _currentRotation -= 45.0;
      if (_currentRotation < 0) _currentRotation += 360.0;
      _mapController.rotate(_currentRotation);
    });
  }

  void _rotateRight() {
    setState(() {
      _currentRotation += 45.0;
      if (_currentRotation >= 360) _currentRotation -= 360.0;
      _mapController.rotate(_currentRotation);
    });
  }

  Future<void> _goToMyLocation() async {
    setState(() {
      _isLoadingGps = true;
    });

    final realLoc = await LocationService().getCurrentDeviceLocation();

    if (mounted) {
      setState(() {
        _userGpsLocation = realLoc;
        _currentZoom = 16.0;
        _isLoadingGps = false;
        _mapController.move(_userGpsLocation, _currentZoom);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Centered on Real Device GPS: Lat ${realLoc.latitude.toStringAsFixed(4)}, Lng ${realLoc.longitude.toStringAsFixed(4)}',
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF800000),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant InteractiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedJob != null) {
      _activeJob = widget.selectedJob;
      _mapController.move(
        LatLng(_activeJob!.customerLat, _activeJob!.customerLng),
        15.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);

    final initialCenter = _activeJob != null
        ? LatLng(_activeJob!.customerLat, _activeJob!.customerLng)
        : _userGpsLocation;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEBE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: maroonColor.withAlpha(75), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // REAL OPENSTREETMAP WORLD MAP LAYER (WITH REAL GPS & ROTATION)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
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
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.hanapgawa.app',
                  tileProvider: CancellableNetworkTileProvider(),
                ),

                MarkerLayer(
                  markers: [
                    // REAL USER'S GPS LOCATION BLUE MARKER
                    Marker(
                      point: _userGpsLocation,
                      width: 100,
                      height: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[900],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Text(
                              'My GPS Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withAlpha(150),
                                  blurRadius: 10,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Customer Job Markers
                    ...widget.jobs.map((job) {
                      final isSelected = _activeJob?.id == job.id;
                      final point = LatLng(job.customerLat, job.customerLng);

                      return Marker(
                        point: point,
                        width: 120,
                        height: 75,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _activeJob = job;
                            });
                            _mapController.move(point, 15.0);
                            if (widget.onJobSelected != null) {
                              widget.onJobSelected!(job);
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? maroonColor : const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.payments,
                                      color: Colors.amberAccent,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '₱${job.hourlyRate.toStringAsFixed(0)}/hr',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),

                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: isSelected ? 38 : 30,
                                height: isSelected ? 38 : 30,
                                decoration: BoxDecoration(
                                  color: isSelected ? maroonColor : Colors.red[700],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isSelected ? maroonColor : Colors.red)
                                          .withAlpha(128),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getCategoryIcon(job.workCategory),
                                  color: Colors.white,
                                  size: isSelected ? 20 : 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),

            // Top Header Location Indicator
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(240),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.public, color: maroonColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _activeJob != null
                            ? 'Location: ${_activeJob!.customerAddress}'
                            : 'Real Device GPS Map — Customer Jobs',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: maroonColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: maroonColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.jobs.length} Jobs',
                        style: const TextStyle(
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
              top: 54,
              right: 10,
              child: Column(
                children: [
                  // My Current Real GPS Location Button
                  Material(
                    color: Colors.blue[800],
                    shape: const CircleBorder(),
                    elevation: 5,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _goToMyLocation,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _isLoadingGps
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.my_location,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rotate Left Button
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _rotateLeft,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.rotate_left, color: maroonColor, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Map Rotation Compass Button
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
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.navigation, color: maroonColor, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rotate Right Button
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _rotateRight,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.rotate_right, color: maroonColor, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Zoom In (+) Button
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _zoomIn,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.add, color: maroonColor, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Zoom Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: maroonColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                    ),
                    child: Text(
                      'Z${_currentZoom.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Zoom Out (-) Button
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _zoomOut,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.remove, color: maroonColor, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Recenter Button
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _resetRecenter,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.center_focus_strong, color: maroonColor, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Selected Job Details Preview Card on Map
            if (_activeJob != null)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: maroonColor, width: 1.2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: maroonColor.withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getCategoryIcon(_activeJob!.workCategory),
                                color: maroonColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _activeJob!.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Customer: ${_activeJob!.customerName} • ${_activeJob!.customerAddress}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Work details summary snippet
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Text(
                            'Details: ${_activeJob!.workDetails}',
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[800],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '₱${_activeJob!.hourlyRate.toStringAsFixed(0)} / hour',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: maroonColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => JobDetailScreen(job: _activeJob!),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: const Text(
                                'View Details',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('Carpentry')) return Icons.construction;
    if (category.contains('Plumbing') || category.contains('Water')) {
      return Icons.plumbing;
    }
    if (category.contains('Electrical')) return Icons.electrical_services;
    if (category.contains('Appliance')) return Icons.hvac;
    if (category.contains('Painting')) return Icons.format_paint;
    if (category.contains('Masonry')) return Icons.handyman;
    if (category.contains('Cleaning')) return Icons.cleaning_services;
    if (category.contains('Garden')) return Icons.grass;
    return Icons.work;
  }
}
