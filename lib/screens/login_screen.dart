import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
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
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  UserRole _selectedRole = UserRole.customer;
  final DataService _dataService = DataService();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');
      final remember = prefs.getBool('remember_me') ?? false;

      if (remember && savedEmail != null && savedPassword != null && mounted) {
        setState(() {
          _emailCtrl.text = savedEmail;
          _passwordCtrl.text = savedPassword;
          _rememberMe = true;
        });
      }
    } catch (e) {
      // Ignore preference errors
    }
  }

  Future<void> _saveOrClearCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_email', email);
        await prefs.setString('saved_password', password);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
        await prefs.setBool('remember_me', false);
      }
    } catch (e) {
      // Ignore preference errors
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



  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final typedEmail = _emailCtrl.text.trim();
    final typedPassword = _passwordCtrl.text.trim();

    final isCustomInput = typedEmail.isNotEmpty || typedPassword.isNotEmpty;

    final email = typedEmail.isNotEmpty
        ? typedEmail
        : (_selectedRole == UserRole.customer
            ? 'juan.customer@gmail.com'
            : 'juan.carpentry@gmail.com');

    final password = typedPassword.isNotEmpty ? typedPassword : 'password123';

    await _saveOrClearCredentials(email, password);

    // Validate email format if typed
    if (typedEmail.isNotEmpty && !typedEmail.contains('@')) {
      _showErrorNotification('Invalid email format. Please enter a valid email address.');
      return;
    }

    if (_selectedRole == UserRole.customer) {
      bool isConfirmed = true;
      if (SupabaseService().isInitialized) {
        final authResponse = await SupabaseService().signIn(email: email, password: password);
        if (!mounted) return;
        if (authResponse == null || authResponse.user == null) {
          if (isCustomInput) {
            _showErrorNotification('Incorrect email or password. Please check your details and try again.');
            return;
          }
        } else {
          isConfirmed = await SupabaseService().isEmailConfirmed();
          if (!mounted) return;
        }
      }

      if (!isConfirmed) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => EmailConfirmationWaitingDialog(
              email: email,
              onConfirmed: () {
                _proceedToCustomerHome(email);
              },
            ),
          );
        }
      } else {
        _proceedToCustomerHome(email);
      }
    } else {
      if (SupabaseService().isInitialized && isCustomInput) {
        final authResponse = await SupabaseService().signIn(email: email, password: password);
        if (authResponse == null || authResponse.user == null) {
          _showErrorNotification('Incorrect email or password. Please check your details and try again.');
          return;
        }
      }

      final worker = _dataService.workers.firstWhere(
        (w) => w.email.toLowerCase() == email.toLowerCase(),
        orElse: () => _dataService.workers.first,
      );
      _dataService.setLoggedInWorker(worker);
      Navigator.pushReplacement(
        context,
        _smoothRoute(const WorkerHomeScreen()),
      );
    }
  }

  void _showErrorNotification(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _proceedToCustomerHome(String email) async {
    CustomerModel? existingCustomer = await SupabaseService().getCustomerByEmail(email);

    if (existingCustomer == null && _dataService.currentCustomer != null && _dataService.currentCustomer!.email.toLowerCase() == email.toLowerCase()) {
      existingCustomer = _dataService.currentCustomer;
    }

    final nameFromEmail = email.split('@').first;
    final formattedName = nameFromEmail.isNotEmpty
        ? nameFromEmail[0].toUpperCase() + nameFromEmail.substring(1)
        : 'Valued Client';

    final customer = existingCustomer ?? CustomerModel(
      id: 'c_${email.hashCode}',
      name: formattedName,
      email: email,
      phone: '0917-888-9900',
      birthday: '1995-04-12',
      address: 'Naval, Biliran, Philippines',
    );

    _dataService.setLoggedInCustomer(customer);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        _smoothRoute(const CustomerHomeScreen()),
      );
    }
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
                  elevation: 6,
                  shadowColor: maroonColor.withAlpha(38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _selectedRole == UserRole.customer
                                ? 'Welcome Back, Customer!'
                                : 'Welcome Back, Pro Worker!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: maroonColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedRole == UserRole.customer
                                ? 'Sign in to book trusted local experts'
                                : 'Sign in to manage jobs & check real-time map',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Email field
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              hintText: _selectedRole == UserRole.customer
                                  ? 'juan.customer@gmail.com'
                                  : 'juan.carpentry@gmail.com',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: const Icon(Icons.email_outlined, color: maroonColor),
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
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'password123',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: const Icon(Icons.lock_outline, color: maroonColor),
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
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Remember Me Checkbox
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: maroonColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _rememberMe = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember Me',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Sign In Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: maroonColor,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: maroonColor.withAlpha(102),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _login,
                            child: Text(
                              _selectedRole == UserRole.customer
                                  ? 'LOGIN AS CUSTOMER'
                                  : 'LOGIN AS WORKER',
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
            final nav = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            final confirmed = await SupabaseService().isEmailConfirmed();
            if (!mounted) return;
            if (confirmed) {
              _timer?.cancel();
              nav.pop();
              widget.onConfirmed();
            } else {
              messenger.showSnackBar(
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
