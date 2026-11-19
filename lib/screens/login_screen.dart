import 'package:flutter/material.dart';
import 'dart:async';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../services/supabase_service.dart';
import '../widgets/hanap_gawa_logo.dart';
import 'signup_screen.dart';
import 'customer_home_screen.dart';
import 'worker_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'juan.customer@gmail.com');
  final _passwordCtrl = TextEditingController(text: 'password123');

  UserRole _selectedRole = UserRole.customer;
  final DataService _dataService = DataService();

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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (_selectedRole == UserRole.customer) {
      bool isConfirmed = true;
      try {
        final authResponse = await SupabaseService().signIn(email: email, password: password);
        if (authResponse != null && authResponse.user != null) {
          isConfirmed = await SupabaseService().isEmailConfirmed();
        }
      } catch (e) {
        // Fallback for offline/mock mode
      }

      if (!isConfirmed) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => EmailConfirmationWaitingDialog(
              email: email,
              onConfirmed: () {
                _proceedToCustomerHome();
              },
            ),
          );
        }
      } else {
        _proceedToCustomerHome();
      }
    } else {
      final worker = _dataService.workers.first;
      _dataService.setLoggedInWorker(worker);
      Navigator.pushReplacement(
        context,
        _smoothRoute(const WorkerHomeScreen()),
      );
    }
  }

  void _proceedToCustomerHome() {
    final customer = CustomerModel(
      id: 'c_user',
      name: 'Juan Dela Cruz',
      email: _emailCtrl.text.trim(),
      phone: '0917-888-9900',
      birthday: '1995-04-12',
      address: 'España Blvd, Sampaloc, Manila',
    );
    _dataService.setLoggedInCustomer(customer);
    Navigator.pushReplacement(
      context,
      _smoothRoute(const CustomerHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HanapGawaLogo(size: 90),
                const SizedBox(height: 24),

                // Role Selector Switcher (Customer vs Worker)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = UserRole.customer),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == UserRole.customer
                                  ? maroonColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person,
                                  color: _selectedRole == UserRole.customer
                                      ? Colors.white
                                      : Colors.grey[700],
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Customer (User)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _selectedRole == UserRole.customer
                                        ? Colors.white
                                        : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedRole = UserRole.worker;
                            _emailCtrl.text = 'juan.carpentry@gmail.com';
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == UserRole.worker
                                  ? maroonColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.handyman,
                                  color: _selectedRole == UserRole.worker
                                      ? Colors.white
                                      : Colors.grey[700],
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Worker (Pro)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _selectedRole == UserRole.worker
                                        ? Colors.white
                                        : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _selectedRole == UserRole.customer
                                ? 'Customer Sign In'
                                : 'Worker Sign In',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: maroonColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedRole == UserRole.customer
                                ? 'Book skilled workers for plumbing, carpentry, etc.'
                                : 'Accept job requests and view customer locations',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          // Email field
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email / Contact Number',
                              prefixIcon: Icon(Icons.email, color: maroonColor),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Please enter email' : null,
                          ),
                          const SizedBox(height: 14),

                          // Password field
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock, color: maroonColor),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.length < 4)
                                ? 'Password too short'
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Sign In Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: maroonColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _login,
                            child: Text(
                              _selectedRole == UserRole.customer
                                  ? 'LOGIN AS CUSTOMER'
                                  : 'LOGIN AS WORKER',
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
                ),
                const SizedBox(height: 20),

                // Don't have an account? Sign up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          _smoothRoute(SignupScreen(initialRole: _selectedRole)),
                        );
                      },
                      child: const Text(
                        'SIGN UP HERE',
                        style: TextStyle(
                          color: maroonColor,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
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
    );
  }
}

class EmailConfirmationWaitingDialog extends StatefulWidget {
  final String email;
  final VoidCallback onConfirmed;

  const EmailConfirmationWaitingDialog({
    super.key,
    required this.email,
    required this.onConfirmed,
  });

  @override
  State<EmailConfirmationWaitingDialog> createState() => _EmailConfirmationWaitingDialogState();
}

class _EmailConfirmationWaitingDialogState extends State<EmailConfirmationWaitingDialog> {
  Timer? _timer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final confirmed = await SupabaseService().isEmailConfirmed();
      if (confirmed && mounted) {
        _timer?.cancel();
        Navigator.pop(context);
        widget.onConfirmed();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    final success = await SupabaseService().resendVerificationEmail(widget.email);
    setState(() => _isResending = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Verification email resent successfully!' : 'Failed to resend email.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.mark_email_unread, color: maroonColor, size: 26),
          SizedBox(width: 8),
          Text('Confirm Your Email First'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your email (${widget.email}) is not verified yet.\n\nPlease check your inbox and click the email confirmation link sent by Supabase.',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: maroonColor),
          const SizedBox(height: 14),
          const Text(
            'Waiting for confirmation...',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isResending ? null : _resendEmail,
          child: _isResending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: maroonColor),
                )
              : const Text('Resend Email', style: TextStyle(color: maroonColor, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: maroonColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final confirmed = await SupabaseService().isEmailConfirmed();
            if (confirmed && mounted) {
              _timer?.cancel();
              Navigator.pop(context);
              widget.onConfirmed();
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email not confirmed yet. Please verify your email inbox.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          child: const Text('I HAVE CONFIRMED'),
        ),
      ],
    );
  }
}
