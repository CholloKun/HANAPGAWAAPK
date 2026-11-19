import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../screens/job_detail_screen.dart';

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
  JobBooking? _activeJob;

  final TransformationController _transformationController = TransformationController();
  double _currentZoomScale = 1.0;

  @override
  void initState() {
    super.initState();
    _activeJob = widget.selectedJob ?? (widget.jobs.isNotEmpty ? widget.jobs.first : null);
    _transformationController.addListener(_onZoomChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onZoomChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onZoomChanged() {
    final double scale = _transformationController.value.getMaxScaleOnAxis();
    if (mounted) {
      setState(() {
        _currentZoomScale = scale;
      });
    }
  }

  void _zoomIn() {
    final double newScale = (_currentZoomScale * 1.3).clamp(0.8, 3.5);
    _setZoom(newScale);
  }

  void _zoomOut() {
    final double newScale = (_currentZoomScale / 1.3).clamp(0.8, 3.5);
    _setZoom(newScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _currentZoomScale = 1.0;
    });
  }

  void _setZoom(double targetScale) {
    _transformationController.value = Matrix4.diagonal3Values(targetScale, targetScale, 1.0);
    setState(() {
      _currentZoomScale = targetScale;
    });
  }

  @override
  void didUpdateWidget(covariant InteractiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedJob != null) {
      _activeJob = widget.selectedJob;
    }
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEBE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: maroonColor.withAlpha(75), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Zoomable & Pannable Interactive Map Layer
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.8,
              maxScale: 3.5,
              boundaryMargin: const EdgeInsets.all(80),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  children: [
                    // Custom Stylized Map Grid Background
                    CustomPaint(
                      size: Size.infinite,
                      painter: _MapGridPainter(),
                    ),

                    // Customer Location Pins with Money Rate per Hour Badge & Work Title
                    ...widget.jobs.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final job = entry.value;
                      final isSelected = _activeJob?.id == job.id;

                      // Compute simulated map coordinates inside container grid
                      final double left = 30 + ((idx * 85 + 40) % 240).toDouble();
                      final double top = 40 + ((idx * 65 + 30) % 180).toDouble();

                      return Positioned(
                        left: left,
                        top: top,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _activeJob = job;
                            });
                            if (widget.onJobSelected != null) {
                              widget.onJobSelected!(job);
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Rate Tag Banner above Pin
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? maroonColor : const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.payments,
                                      color: Colors.amberAccent,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '₱${job.hourlyRate.toStringAsFixed(0)}/hr',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 2),

                              // Location Pin Icon
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: isSelected ? 42 : 34,
                                height: isSelected ? 42 : 34,
                                decoration: BoxDecoration(
                                  color: isSelected ? maroonColor : Colors.red[700],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isSelected ? maroonColor : Colors.red)
                                          .withAlpha(128),
                                      blurRadius: 8,
                                      spreadRadius: isSelected ? 3 : 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getCategoryIcon(job.workCategory),
                                  color: Colors.white,
                                  size: isSelected ? 22 : 18,
                                ),
                              ),

                              // Customer Name under pin
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(230),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  job.customerName.split(' ').first,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Map Header Control Bar
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
                    const Icon(Icons.my_location, color: maroonColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _activeJob != null
                            ? 'Customer Location: ${_activeJob!.customerAddress}'
                            : 'Interactive Map — Customers in Need',
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
                        '${widget.jobs.length} Active Jobs',
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

            // Floating Zoom In / Zoom Out Controls Bar
            Positioned(
              top: 54,
              right: 10,
              child: Column(
                children: [
                  // Zoom In Button (+)
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

                  // Zoom Scale Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: maroonColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                    ),
                    child: Text(
                      '${(_currentZoomScale * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Zoom Out Button (-)
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

                  // Recenter / Reset Zoom Button
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _resetZoom,
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
                            // Hourly Rate Highlight
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

                            // View Full Job Details Button
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

// Custom Painter for Map Roads and Landmarks Grid
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFD4C5B9)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    final secondaryRoadPaint = Paint()
      ..color = Colors.white.withAlpha(204)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final parkPaint = Paint()..color = const Color(0xFFCBE3C9);
    final waterPaint = Paint()..color = const Color(0xFFA5C9EB);

    // River / Water body
    final waterPath = Path()
      ..moveTo(0, size.height * 0.4)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.25,
        size.width * 0.6,
        size.height * 0.55,
        size.width,
        size.height * 0.45,
      )
      ..lineTo(size.width, size.height * 0.55)
      ..cubicTo(
        size.width * 0.6,
        size.height * 0.65,
        size.width * 0.3,
        size.height * 0.35,
        0,
        size.height * 0.5,
      )
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    // Park green area
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, 20, 90, 60),
        const Radius.circular(12),
      ),
      parkPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.65, size.height * 0.6, 110, 70),
        const Radius.circular(12),
      ),
      parkPaint,
    );

    // Main Roads
    final mainRoad1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.8);

    final mainRoad2 = Path()
      ..moveTo(size.width * 0.4, 0)
      ..lineTo(size.width * 0.4, size.height);

    canvas.drawPath(mainRoad1, roadBorderPaint);
    canvas.drawPath(mainRoad1, roadPaint);

    canvas.drawPath(mainRoad2, roadBorderPaint);
    canvas.drawPath(mainRoad2, roadPaint);

    // Cross Secondary Roads
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width, size.height * 0.2),
      secondaryRoadPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.8, 0),
      Offset(size.width * 0.8, size.height),
      secondaryRoadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
