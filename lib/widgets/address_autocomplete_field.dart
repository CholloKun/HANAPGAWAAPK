import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final Function(String address, double lat, double lng)? onLocationSelected;
  final String? Function(String?)? validator;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    this.labelText = 'Complete Address / Location',
    this.prefixIcon = Icons.location_on_outlined,
    this.onLocationSelected,
    this.validator,
  });

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  List<dynamic> _suggestions = [];
  bool _isLoading = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim();
    if (query.length < 3) {
      _removeOverlay();
      setState(() {
        _suggestions = [];
      });
      return;
    }
    _fetchSuggestions(query);
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final encoded = Uri.encodeComponent(query);
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=$encoded&limit=5');
      final response = await http.get(url, headers: {'User-Agent': 'com.hanapgawa.app'});

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _suggestions = data;
            _isLoading = false;
          });
          _showOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();
    if (_suggestions.isEmpty) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 4.0),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  final displayName = item['display_name'] ?? '';
                  final lat = double.tryParse(item['lat'].toString()) ?? 11.5606;
                  final lon = double.tryParse(item['lon'].toString()) ?? 124.3986;

                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Color(0xFF800000), size: 20),
                    title: Text(
                      displayName,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      widget.controller.text = displayName;
                      if (widget.onLocationSelected != null) {
                        widget.onLocationSelected!(displayName, lat, lon);
                      }
                      _removeOverlay();
                      setState(() {
                        _suggestions = [];
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.labelText,
          prefixIcon: Icon(widget.prefixIcon, color: maroonColor),
          suffixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: maroonColor),
                  ),
                )
              : const Icon(Icons.search, size: 18, color: Colors.grey),
          border: const OutlineInputBorder(),
          hintText: 'Type place or address for live suggestions...',
        ),
        validator: widget.validator,
      ),
    );
  }
}
