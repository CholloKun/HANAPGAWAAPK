import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
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

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == UserRole.customer) {
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
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
      );
    } else {
      final worker = _dataService.workers.first;
      _dataService.setLoggedInWorker(worker);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkerHomeScreen()),
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
                          MaterialPageRoute(
                            builder: (_) => SignupScreen(initialRole: _selectedRole),
                          ),
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
