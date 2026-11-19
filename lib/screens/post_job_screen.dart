import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../widgets/location_picker_dialog.dart';

class PostJobScreen extends StatefulWidget {
  final String? preselectedCategory;
  final String? preselectedWorkerName;
  final double? suggestedRate;

  const PostJobScreen({
    super.key,
    this.preselectedCategory,
    this.preselectedWorkerName,
    this.suggestedRate,
  });

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedCategory;
  final _titleCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _addressCtrl = TextEditingController(text: 'Naval, Biliran, Philippines');
  late TextEditingController _rateCtrl;
  final _hoursCtrl = TextEditingController(text: '3.0');

  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.preselectedCategory ?? WorkCategory.categories.first.title;
    _rateCtrl = TextEditingController(
      text: (widget.suggestedRate ?? 350.0).toStringAsFixed(0),
    );

    if (widget.preselectedWorkerName != null) {
      _titleCtrl.text = 'Work Booking for ${widget.preselectedWorkerName}';
    }
  }

  void _submitJob() {
    if (!_formKey.currentState!.validate()) return;

    final rate = double.tryParse(_rateCtrl.text) ?? 350.0;
    final hours = double.tryParse(_hoursCtrl.text) ?? 2.0;

    _dataService.addJobBooking(
      title: _titleCtrl.text.trim(),
      workCategory: _selectedCategory,
      workDetails: _detailsCtrl.text.trim(),
      hourlyRate: rate,
      estimatedHours: hours,
      address: _addressCtrl.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job Request Posted! Workers can now view location & accept.'),
        backgroundColor: Color(0xFF800000),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);

    final currentRate = double.tryParse(_rateCtrl.text) ?? 0.0;
    final currentHours = double.tryParse(_hoursCtrl.text) ?? 0.0;
    final estimatedTotal = currentRate * currentHours;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Work Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: maroonColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: maroonColor.withAlpha(75)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_location_alt, color: maroonColor, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Post your work details and location on the Map. Proficient workers will see your money rate per hour and accept!',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Type of Work Needed',
                  prefixIcon: Icon(Icons.build, color: maroonColor),
                  border: OutlineInputBorder(),
                ),
                items: WorkCategory.categories
                    .map((c) => DropdownMenuItem(value: c.title, child: Text(c.title)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 14),

              // Job Title
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Job Title / Summary',
                  prefixIcon: Icon(Icons.title, color: maroonColor),
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Leaking pipe repair under sink',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter job title' : null,
              ),
              const SizedBox(height: 14),

              // Work Details
              TextFormField(
                controller: _detailsCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Details of the Work',
                  prefixIcon: Icon(Icons.notes, color: maroonColor),
                  border: OutlineInputBorder(),
                  hintText: 'Describe the issue, tools needed, scope of work, etc.',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter work details'
                    : null,
              ),
              const SizedBox(height: 14),

              // Address / Location with Interactive Map Picker
              TextFormField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Work Location / Address',
                  prefixIcon: const Icon(Icons.location_on, color: maroonColor),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map, color: maroonColor),
                    tooltip: 'Pick Location on Map',
                    onPressed: () async {
                      final selected = await LocationPickerDialog.show(
                        context,
                        initialAddress: _addressCtrl.text,
                      );
                      if (selected != null && selected.isNotEmpty) {
                        setState(() {
                          _addressCtrl.text = selected;
                        });
                      }
                    },
                  ),
                  border: const OutlineInputBorder(),
                  hintText: 'Type address or tap map icon to pick location',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter work location or pick on map'
                    : null,
              ),
              const SizedBox(height: 14),

              // Rate per Hour & Estimated Hours Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Rate per Hour (₱/hr)',
                        prefixIcon: Icon(Icons.payments, color: maroonColor),
                        border: OutlineInputBorder(),
                        suffixText: 'PHP',
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter rate per hour' : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _hoursCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Est. Hours',
                        prefixIcon: Icon(Icons.timer, color: maroonColor),
                        border: OutlineInputBorder(),
                        suffixText: 'hrs',
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter hours' : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Live Total Calculation Preview
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estimated Total Payout:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₱${estimatedTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroonColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _submitJob,
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text(
                  'POST JOB ON MAP & FEED',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
