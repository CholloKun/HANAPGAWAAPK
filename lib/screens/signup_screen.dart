import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../widgets/hanap_gawa_logo.dart';
import '../widgets/location_picker_dialog.dart';
import 'customer_home_screen.dart';
import 'worker_home_screen.dart';

class SignupScreen extends StatefulWidget {
  final UserRole initialRole;

  const SignupScreen({super.key, this.initialRole = UserRole.customer});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shared fields
  late UserRole _role;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController(text: 'Naval, Biliran, Philippines');
  final _passwordCtrl = TextEditingController();

  // Customer specific fields
  final _birthdayCtrl = TextEditingController();

  // Worker specific fields
  String _selectedCategory = WorkCategory.categories.first.title;
  final _hourlyRateCtrl = TextEditingController(text: '350');
  final _workingPermitCtrl = TextEditingController();
  final _nationalCertCtrl = TextEditingController();
  final _proficiencyProofCtrl = TextEditingController();

  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SELECT YOUR BIRTHDAY',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF800000),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _birthdayCtrl.text = formatted;
      });
    }
  }

  void _signup() {
    if (!_formKey.currentState!.validate()) return;

    if (_role == UserRole.customer) {
      _dataService.registerCustomer(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        birthday: _birthdayCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer Account successfully registered! Welcome to Hanap Gawa.'),
          backgroundColor: Color(0xFF800000),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        (route) => false,
      );
    } else {
      _dataService.registerWorker(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        workCategory: _selectedCategory,
        hourlyRate: double.tryParse(_hourlyRateCtrl.text.trim()) ?? 300.0,
        workingPermitNo: _workingPermitCtrl.text.trim(),
        nationalCertificateNo: _nationalCertCtrl.text.trim(),
        proficiencyProof: _proficiencyProofCtrl.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Worker Credentials & Profile registered! Ready to accept jobs.'),
          backgroundColor: Color(0xFF800000),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WorkerHomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);

    return Scaffold(
      appBar: AppBar(
        title: Text(_role == UserRole.customer ? 'Customer Sign Up' : 'Worker Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HanapGawaLogo(size: 70, showSubtitle: false),
              const SizedBox(height: 16),

              // Role Segmented Switch
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = UserRole.customer),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _role == UserRole.customer ? maroonColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              'Register as Customer',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _role == UserRole.customer ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = UserRole.worker),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _role == UserRole.worker ? maroonColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              'Register as Worker',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _role == UserRole.worker ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Shared Personal Details Section Header
              _buildSectionTitle('Personal Details'),
              const SizedBox(height: 12),

              // Full Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person, color: maroonColor),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter full name' : null,
              ),
              const SizedBox(height: 12),

              // Phone Number
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone Number',
                  prefixIcon: Icon(Icons.phone, color: maroonColor),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 7) ? 'Enter valid phone number' : null,
              ),
              const SizedBox(height: 12),

              // Address with Interactive Map Picker
              TextFormField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Complete Address / Location',
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter address or select on map' : null,
              ),
              const SizedBox(height: 12),

              // CUSTOMER SPECIFIC FIELD: Interactive Calendar Birthday Picker
              if (_role == UserRole.customer) ...[
                TextFormField(
                  controller: _birthdayCtrl,
                  readOnly: true,
                  onTap: () => _selectBirthday(context),
                  decoration: InputDecoration(
                    labelText: 'Date of Birth (Birthday)',
                    prefixIcon: const Icon(Icons.cake, color: maroonColor),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month, color: maroonColor),
                      onPressed: () => _selectBirthday(context),
                    ),
                    border: const OutlineInputBorder(),
                    hintText: 'Tap to select Year, Month & Date',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please select your birthday' : null,
                ),
                const SizedBox(height: 12),
              ],

              // Email & Password
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email, color: maroonColor),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Enter valid email address' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock, color: maroonColor),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Password must be at least 6 chars' : null,
              ),
              const SizedBox(height: 20),

              // WORKER SPECIFIC CREDENTIALS SECTION
              if (_role == UserRole.worker) ...[
                _buildSectionTitle('Worker Credentials & Proficiency Documents'),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.amber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Provide working permit & NC II certificates to prove proficiency to customers.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Primary Skill Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Primary Work Specialization',
                    prefixIcon: Icon(Icons.build, color: maroonColor),
                    border: OutlineInputBorder(),
                  ),
                  items: WorkCategory.categories
                      .map((c) => DropdownMenuItem(value: c.title, child: Text(c.title)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 12),

                // Hourly Rate (₱/hr)
                TextFormField(
                  controller: _hourlyRateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Rate per Hour (₱ / hr)',
                    prefixIcon: Icon(Icons.payments, color: maroonColor),
                    border: OutlineInputBorder(),
                    suffixText: 'PHP / hour',
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter hourly rate' : null,
                ),
                const SizedBox(height: 12),

                // Working Permit Number
                TextFormField(
                  controller: _workingPermitCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Working Permit Number / Mayor\'s Permit',
                    prefixIcon: Icon(Icons.badge, color: maroonColor),
                    border: OutlineInputBorder(),
                    hintText: 'e.g. PERMIT-MNL-2024-8842',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter working permit details' : null,
                ),
                const SizedBox(height: 12),

                // National Certificate / TESDA Certificate No.
                TextFormField(
                  controller: _nationalCertCtrl,
                  decoration: const InputDecoration(
                    labelText: 'National Certificate (NC II / TESDA No.)',
                    prefixIcon: Icon(Icons.card_membership, color: maroonColor),
                    border: OutlineInputBorder(),
                    hintText: 'e.g. TESDA-NC2-PLUMB-44810',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter National Certificate No.' : null,
                ),
                const SizedBox(height: 12),

                // Proof of Proficiency Document Details
                TextFormField(
                  controller: _proficiencyProofCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Proficiency Proof / Experience Documents',
                    prefixIcon: Icon(Icons.description, color: maroonColor),
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 5+ years experience, Licensed Master Plumber, TESDA NC II Certified',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter proficiency proof details' : null,
                ),
                const SizedBox(height: 20),
              ],

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroonColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _signup,
                child: Text(
                  _role == UserRole.customer
                      ? 'COMPLETE CUSTOMER SIGN UP'
                      : 'REGISTER WORKER PROFILE',
                  style: const TextStyle(
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

  Widget _buildSectionTitle(String title) {
    const maroonColor = Color(0xFF800000);
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: maroonColor,
        ),
      ),
    );
  }
}
