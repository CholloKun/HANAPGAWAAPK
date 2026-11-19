import 'package:flutter/material.dart';

class LocationPickerDialog extends StatefulWidget {
  final String initialAddress;

  const LocationPickerDialog({
    super.key,
    this.initialAddress = 'Sampaloc, Manila',
  });

  static Future<String?> show(BuildContext context, {String initialAddress = ''}) {
    return showDialog<String>(
      context: context,
      builder: (_) => LocationPickerDialog(
        initialAddress: initialAddress.isNotEmpty ? initialAddress : 'Sampaloc, Manila',
      ),
    );
  }

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late TextEditingController _addressCtrl;
  Offset _pinPosition = const Offset(160, 100);

  final TransformationController _transformationController = TransformationController();
  double _currentZoomScale = 1.0;

  final List<Map<String, String>> _popularLocations = [
    {'name': 'Sampaloc, Manila', 'full': '123 España Blvd, Sampaloc, Manila'},
    {'name': 'Katipunan, QC', 'full': '45 Katipunan Ave, Loyola Heights, Quezon City'},
    {'name': 'Ayala, Makati', 'full': '78 Ayala Ave, Bel-Air, Makati City'},
    {'name': 'Shaw Blvd, Mandaluyong', 'full': '99 Shaw Blvd, Highway Hills, Mandaluyong'},
    {'name': 'BGC, Taguig', 'full': '26th Street, Bonifacio Global City, Taguig'},
    {'name': 'Ortigas, Pasig', 'full': 'Julia Vargas Ave, Ortigas Center, Pasig City'},
    {'name': 'Diliman, QC', 'full': 'Commonwealth Ave, Diliman, Quezon City'},
  ];

  @override
  void initState() {
    super.initState();
    _addressCtrl = TextEditingController(text: widget.initialAddress);
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
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: maroonColor,
                child: const Row(
                  children: [
                    Icon(Icons.map, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Select Location on Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive Zoomable Map Simulation with Pin
              Container(
                height: 240,
                color: const Color(0xFFEFEBE7),
                child: Stack(
                  children: [
                    InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.8,
                      maxScale: 3.5,
                      child: GestureDetector(
                        onTapDown: (details) {
                          setState(() {
                            _pinPosition = details.localPosition;
                          });
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Stack(
                            children: [
                              CustomPaint(
                                size: Size.infinite,
                                painter: _MapRoadsPainter(),
                              ),

                              // Location Pin
                              Positioned(
                                left: _pinPosition.dx - 20,
                                top: _pinPosition.dy - 40,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: maroonColor,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'Selected Pin',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.location_on,
                                      color: maroonColor,
                                      size: 40,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.touch_app, size: 16, color: maroonColor),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Tap to place pin. Pinch or tap +/- to zoom.',
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

                    // Floating Zoom Controls (+ / - / Reset)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: maroonColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(_currentZoomScale * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
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
                          Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _resetZoom,
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

              // Popular Location Presets
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Location Presets:',
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
                                loc['name']!,
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: maroonColor.withOpacity(0.08),
                              labelStyle: const TextStyle(color: maroonColor),
                              onPressed: () {
                                setState(() {
                                  _addressCtrl.text = loc['full']!;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Manual / Selected Address TextFormField
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Selected Address / Location',
                        prefixIcon: Icon(Icons.pin_drop, color: maroonColor),
                        border: OutlineInputBorder(),
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

class _MapRoadsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final waterPaint = Paint()..color = const Color(0xFFA5C9EB);
    final parkPaint = Paint()..color = const Color(0xFFCBE3C9);

    // Park
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 10, 80, 50),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    // River
    final waterPath = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.5,
        size.width,
        size.height * 0.8,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    // Roads
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      roadPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.4, 0),
      Offset(size.width * 0.4, size.height),
      roadPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width * 0.75, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
