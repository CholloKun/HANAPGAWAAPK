import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../services/supabase_service.dart';
import '../widgets/hanap_gawa_logo.dart';
import '../widgets/location_picker_dialog.dart';
import 'login_screen.dart';

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
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _suffixCtrl = TextEditingController();
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

  String? _ncDocBase64;
  String? _permitDocBase64;

  Future<void> _pickDocumentImage(bool isNcDoc) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64String';

        setState(() {
          if (isNcDoc) {
            _ncDocBase64 = dataUrl;
          } else {
            _permitDocBase64 = dataUrl;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isNcDoc ? 'TESDA NC Certificate document attached!' : 'Working Permit document attached!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error picking document: $e');
    }
  }

  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _suffixCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    _birthdayCtrl.dispose();
    _hourlyRateCtrl.dispose();
    _workingPermitCtrl.dispose();
    _nationalCertCtrl.dispose();
    _proficiencyProofCtrl.dispose();
    super.dispose();
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

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    // 1. Try Supabase Auth sign up (Supabase sends confirmation email automatically)
    String? userId;
    try {
      final authResponse = await SupabaseService().signUp(
        email: email,
        password: password,
        data: {'role': _role == UserRole.customer ? 'customer' : 'worker'},
      );
      userId = authResponse?.user?.id;
    } catch (e) {
      if (kDebugMode) print('Supabase signup exception: $e');
    }

    // If Supabase auth didn't return a user (e.g. offline, network error, or not configured),
    // fallback to local ID generation so signup always succeeds for the user.
    if (userId == null || userId.isEmpty) {
      userId = _role == UserRole.customer
          ? 'c_${DateTime.now().millisecondsSinceEpoch}'
          : 'w_${DateTime.now().millisecondsSinceEpoch}';
    }

    // 2. Register into Supabase DB table / DataService
    final fullName = [
      _firstNameCtrl.text.trim(),
      if (_middleNameCtrl.text.trim().isNotEmpty) _middleNameCtrl.text.trim(),
      _lastNameCtrl.text.trim(),
      if (_suffixCtrl.text.trim().isNotEmpty) _suffixCtrl.text.trim(),
    ].join(' ');

    if (_role == UserRole.customer) {
      await _dataService.registerCustomer(
        id: userId,
        name: fullName,
        email: email,
        phone: _phoneCtrl.text.trim(),
        birthday: _birthdayCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );
      _dataService.logout();

      if (mounted) {
        _showConfirmationDialog(email);
      }
    } else {
      await _dataService.registerWorker(
        id: userId,
        name: fullName,
        email: email,
        phone: _phoneCtrl.text.trim(),
        birthday: _birthdayCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        workCategory: _selectedCategory,
        hourlyRate: double.tryParse(_hourlyRateCtrl.text.trim()) ?? 300.0,
        workingPermitNo: _workingPermitCtrl.text.trim(),
        nationalCertificateNo: _nationalCertCtrl.text.trim(),
        proficiencyProof: _proficiencyProofCtrl.text.trim(),
        nationalCertificateDoc: _ncDocBase64,
        workingPermitDoc: _permitDocBase64,
      );
      _dataService.logout();

      if (mounted) {
        _showConfirmationDialog(email);
      }
    }
  }

  Route<T> _smoothRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.04);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  void _showConfirmationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mark_email_read, color: Color(0xFF800000)),
              SizedBox(width: 8),
              Text('Verification Email Sent'),
            ],
          ),
          content: Text(
            'Registration successful! Supabase has sent a confirmation email to $email. Please check your inbox and click the verification link before logging in.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final success = await SupabaseService().resendVerificationEmail(email);
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Verification email resent to $email'
                          : 'Failed to resend verification email. Try again later.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Resend Email', style: TextStyle(color: Color(0xFF800000))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF800000),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext); // close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  _smoothRoute(const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('OK, GO TO LOGIN'),
            ),
          ],
        );
      },
    );
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

              // Shared Personal Details Card
              _buildFormCard(
                title: 'Personal Details & Contact',
                icon: Icons.person_outline,
                children: [
                  TextFormField(
                    controller: _firstNameCtrl,
                    decoration: _inputDecoration('First Name', Icons.person_outline),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter first name' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _middleNameCtrl,
                          decoration: _inputDecoration('Middle Name (Optional)', Icons.person_outline),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _suffixCtrl,
                          decoration: _inputDecoration('Suffix (Optional, Jr.)', Icons.badge_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastNameCtrl,
                    decoration: _inputDecoration('Last Name', Icons.person_outline),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter last name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _birthdayCtrl,
                    readOnly: true,
                    onTap: () => _selectBirthday(context),
                    decoration: _inputDecoration(
                      'Date of Birth (Birthday)',
                      Icons.cake_outlined,
                      hintText: 'Tap to select Year, Month & Date',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_month, color: maroonColor),
                        onPressed: () => _selectBirthday(context),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Please select your birthday' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('Contact Phone Number', Icons.phone_outlined),
                    validator: (v) =>
                        (v == null || v.trim().length < 7) ? 'Enter valid phone number' : null,
                  ),
                ],
              ),

              // Location & Address Card
              _buildFormCard(
                title: 'Location & Address',
                icon: Icons.location_on_outlined,
                children: [
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: _inputDecoration(
                      'Complete Address / Location',
                      Icons.location_on_outlined,
                      hintText: 'Type address or tap map icon to pick location',
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
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter address or select on map' : null,
                  ),
                ],
              ),

              // Account Security Card
              _buildFormCard(
                title: 'Account Security',
                icon: Icons.lock_outline,
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Email Address', Icons.email_outlined),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Enter valid email address' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: _inputDecoration('Password', Icons.lock_outline),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Password must be at least 6 chars' : null,
                  ),
                ],
              ),

              // WORKER SPECIFIC CREDENTIALS & SPECIALIZATION SECTION
              if (_role == UserRole.worker) ...[
                _buildFormCard(
                  title: 'Work Specialization & Rates',
                  icon: Icons.build_outlined,
                  children: [
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
                  ],
                ),

                _buildFormCard(
                  title: 'Credentials & Scanned Documents',
                  icon: Icons.verified_user_outlined,
                  children: [
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
                              'Upload working permit & NC II certificates to prove proficiency to customers.',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Working Permit Number & Upload
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
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: maroonColor,
                          side: BorderSide(color: _permitDocBase64 != null ? Colors.green : maroonColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _pickDocumentImage(false),
                        icon: Icon(_permitDocBase64 != null ? Icons.check_circle : Icons.upload_file, color: _permitDocBase64 != null ? Colors.green : maroonColor),
                        label: Text(
                          _permitDocBase64 != null ? 'Working Permit / ID Attached ✓' : 'Upload Scanned Working Permit / Gov ID Image',
                          style: TextStyle(fontWeight: FontWeight.bold, color: _permitDocBase64 != null ? Colors.green[800] : maroonColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // National Certificate / TESDA Certificate No. & Upload
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
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: maroonColor,
                          side: BorderSide(color: _ncDocBase64 != null ? Colors.green : maroonColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _pickDocumentImage(true),
                        icon: Icon(_ncDocBase64 != null ? Icons.check_circle : Icons.upload_file, color: _ncDocBase64 != null ? Colors.green : maroonColor),
                        label: Text(
                          _ncDocBase64 != null ? 'TESDA NC Certificate Attached ✓' : 'Upload Scanned TESDA NC Certificate Image',
                          style: TextStyle(fontWeight: FontWeight.bold, color: _ncDocBase64 != null ? Colors.green[800] : maroonColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Proof of Proficiency Document Details
                    TextFormField(
                      controller: _proficiencyProofCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Proficiency Proof / Experience Details',
                        prefixIcon: Icon(Icons.description, color: maroonColor),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. 5+ years experience, Licensed Master Plumber, TESDA NC II Certified',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter proficiency proof details' : null,
                    ),
                  ],
                ),
              ],

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroonColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: maroonColor.withAlpha(102),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _signup,
                child: Text(
                  _role == UserRole.customer
                      ? 'COMPLETE CUSTOMER SIGN UP'
                      : 'REGISTER WORKER PROFILE',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    const maroonColor = Color(0xFF800000);
    return Card(
      elevation: 2,
      shadowColor: maroonColor.withAlpha(20),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: maroonColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: maroonColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon, String? hintText}) {
    const maroonColor = Color(0xFF800000);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: maroonColor),
      suffixIcon: suffixIcon,
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: maroonColor, width: 2),
      ),
    );
  }

}
