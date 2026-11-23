import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import 'supabase_service.dart';

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal() {
    _syncWithSupabase();
  }

  final SupabaseService _supabaseService = SupabaseService();

  UserRole _currentUserRole = UserRole.customer;
  CustomerModel? _currentCustomer;
  WorkerModel? _currentWorker;

  UserRole get currentUserRole => _currentUserRole;
  CustomerModel? get currentCustomer => _currentCustomer;
  WorkerModel? get currentWorker => _currentWorker;

  bool get isLoggedIn => _currentCustomer != null || _currentWorker != null;

  // Notifications List
  final List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;

  // Sync jobs and notifications from Supabase
  Future<void> syncWithSupabase() async {
    final customerId = (_currentUserRole == UserRole.customer && _currentCustomer != null) ? _currentCustomer!.id : null;

    final remoteJobs = await _supabaseService.fetchJobs(customerId: customerId);
    _jobs.clear();
    _jobs.addAll(remoteJobs);

    final remoteWorkers = await _supabaseService.fetchWorkers();
    if (remoteWorkers.isNotEmpty) {
      _workers.clear();
      _workers.addAll(remoteWorkers);
    }

    if (_currentCustomer != null) {
      final remoteNotifs = await _supabaseService.fetchNotifications(_currentCustomer!.id);
      _notifications.clear();
      _notifications.addAll(remoteNotifs);
    }

    notifyListeners();
  }

  Future<void> _syncWithSupabase() async {
    await syncWithSupabase();
  }

  // Registered Skilled Workers
  final List<WorkerModel> _workers = [];

  // Job Bookings List in Naval, Biliran, Philippines
  final List<JobBooking> _jobs = [
    JobBooking(
      id: 'job-101',
      customerId: 'c1',
      customerName: 'Maria Clara Santos',
      customerPhone: '0917-123-9988',
      customerAddress: 'Brgy. Smo. Rosario, Naval, Biliran, Philippines',
      customerLat: 11.5615,
      customerLng: 124.3975,
      workCategory: 'Water Repairman / Plumbing',
      title: 'Emergency Leaking Pipe Repair under Kitchen Sink',
      workDetails: 'Main kitchen pipe broke and leaking water heavily onto floor. Needs urgent repair, replacement of PVC connectors, and sealant application.',
      hourlyRate: 350.0,
      estimatedHours: 3.0,
      workersNeeded: 1,
      status: 'Pending',
      createdAt: '2025-02-23 09:30 AM',
    ),
    JobBooking(
      id: 'job-102',
      customerId: 'c2',
      customerName: 'Pedro Penduko',
      customerPhone: '0928-444-1122',
      customerAddress: 'Brgy. Caraycaray, Naval, Biliran, Philippines',
      customerLat: 11.5530,
      customerLng: 124.4080,
      workCategory: 'Carpentry',
      title: 'Wooden Cabinet & Door Hinge Repair',
      workDetails: 'Custom wooden kitchen cabinet doors sagging, alignment adjustment needed, plus repairing 2 bedroom doors that catch on the floor.',
      hourlyRate: 300.0,
      estimatedHours: 4.0,
      workersNeeded: 1,
      status: 'Pending',
      createdAt: '2025-02-23 10:15 AM',
    ),
    JobBooking(
      id: 'job-103',
      customerId: 'c3',
      customerName: 'Ana Patricia Non',
      customerPhone: '0919-888-3344',
      customerAddress: 'BiPSU Main Campus, Naval, Biliran, Philippines',
      customerLat: 11.5660,
      customerLng: 124.4005,
      workCategory: 'Electrical',
      title: 'Main Switch Board Breaker Tripping & Socket Installation',
      workDetails: 'Air conditioner outlet keeps tripping circuit breaker when turned on. Need licensed electrician to inspect breaker box and install dedicated 20A outlet line.',
      hourlyRate: 400.0,
      estimatedHours: 2.5,
      workersNeeded: 1,
      status: 'Accepted',
      assignedWorkerId: 'w3',
      assignedWorkerName: 'Engr. Joey Sparks (Electrician)',
      createdAt: '2025-02-22 04:45 PM',
    ),
  ];

  List<WorkerModel> get workers => List.unmodifiable(_workers);
  List<JobBooking> get jobs => List.unmodifiable(_jobs);

  List<WorkerModel> getWorkersByCategory(String category) {
    if (category == 'All') return _workers;
    return _workers.where((w) => w.workCategory == category).toList();
  }

  // Set default logged in user for testing/initial state with SharedPreferences profile picture cache
  Future<void> setLoggedInCustomer(CustomerModel customer) async {
    CustomerModel loaded = customer;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedImage = prefs.getString('profile_image_${customer.email}');
      if (cachedImage != null && cachedImage.isNotEmpty) {
        loaded = customer.copyWith(profileImagePath: cachedImage);
      }
    } catch (e) {
      // Ignore
    }

    _currentUserRole = UserRole.customer;
    _currentCustomer = loaded;
    _currentWorker = null;
    
    // Load customer notifications
    final notifs = await _supabaseService.fetchNotifications(loaded.id);
    if (notifs.isNotEmpty) {
      _notifications.clear();
      _notifications.addAll(notifs);
    } else if (_notifications.isEmpty) {
      // Add welcome notification
      final welcome = NotificationModel(
        id: 'notif_welcome_${DateTime.now().millisecondsSinceEpoch}',
        userId: loaded.id,
        title: 'Welcome to Hanap Gawa! 🛠️',
        message: 'Browse trusted local workers or post your service request on the map.',
        createdAt: DateTime.now().toString().split('.').first,
      );
      _notifications.add(welcome);
    }

    notifyListeners();
  }

  void setLoggedInWorker(WorkerModel worker) {
    _currentUserRole = UserRole.worker;
    _currentWorker = worker;
    _currentCustomer = null;
    notifyListeners();
  }

  void switchRole(UserRole role) {
    _currentUserRole = role;
    notifyListeners();
  }

  void logout() {
    _currentCustomer = null;
    _currentWorker = null;
    _notifications.clear();
    notifyListeners();
  }

  Future<void> updateCustomerProfile({
    String? name,
    String? phone,
    String? birthday,
    String? address,
    String? profileImagePath,
  }) async {
    if (_currentCustomer != null) {
      String? finalImagePath = profileImagePath ?? _currentCustomer!.profileImagePath;

      // Convert image file to base64 data URL for SharedPreferences persistence
      if (profileImagePath != null && profileImagePath.isNotEmpty && !profileImagePath.startsWith('data:')) {
        try {
          final file = File(profileImagePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final base64Str = base64Encode(bytes);
            final mimeType = profileImagePath.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
            finalImagePath = 'data:$mimeType;base64,$base64Str';

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('profile_image_${_currentCustomer!.email}', finalImagePath);
          }
        } catch (e) {
          if (kDebugMode) print('Error caching profile image: $e');
        }
      }

      _currentCustomer = _currentCustomer!.copyWith(
        name: name,
        phone: phone,
        birthday: birthday,
        address: address,
        profileImagePath: finalImagePath,
      );
      _supabaseService.saveCustomer(_currentCustomer!);
      notifyListeners();
    }
  }

  Future<CustomerModel> registerCustomer({
    String? id,
    required String name,
    required String email,
    required String phone,
    required String birthday,
    required String address,
  }) async {
    final newCustomer = CustomerModel(
      id: (id != null && id.isNotEmpty) ? id : 'c_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      birthday: birthday,
      address: address,
      latitude: 11.5606 + (DateTime.now().millisecond % 50) * 0.0002,
      longitude: 124.3986 + (DateTime.now().millisecond % 50) * 0.0002,
    );
    await setLoggedInCustomer(newCustomer);
    await _supabaseService.saveCustomer(newCustomer);
    return newCustomer;
  }

  Future<WorkerModel> registerWorker({
    String? id,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String workCategory,
    required double hourlyRate,
    required String workingPermitNo,
    required String nationalCertificateNo,
    required String proficiencyProof,
  }) async {
    final newWorker = WorkerModel(
      id: (id != null && id.isNotEmpty) ? id : 'w_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      address: address,
      workCategory: workCategory,
      hourlyRate: hourlyRate,
      workingPermitNo: workingPermitNo,
      nationalCertificateNo: nationalCertificateNo,
      proficiencyProof: proficiencyProof,
      latitude: 11.5610 + (DateTime.now().millisecond % 40) * 0.0002,
      longitude: 124.3990 + (DateTime.now().millisecond % 40) * 0.0002,
    );
    _workers.add(newWorker);
    setLoggedInWorker(newWorker);
    await _supabaseService.saveWorker(newWorker);
    return newWorker;
  }

  Future<void> addJobBooking({
    required String title,
    required String workCategory,
    required String workDetails,
    required double hourlyRate,
    required double estimatedHours,
    required int workersNeeded,
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    final cust = _currentCustomer ??
        CustomerModel(
          id: 'c_default',
          name: 'Juan Dela Cruz',
          email: 'user@hanapgawa.com',
          phone: '0917-000-1111',
          birthday: '1995-05-15',
          address: address.isNotEmpty ? address : 'Naval, Biliran, Philippines',
        );

    double lat = latitude ?? cust.latitude;
    double lng = longitude ?? cust.longitude;

    if (latitude == null || longitude == null) {
      try {
        final encodedAddr = Uri.encodeComponent(address);
        final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=$encodedAddr&limit=1');
        final response = await http.get(
          url,
          headers: {'User-Agent': 'com.hanapgawa.app'},
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final List data = json.decode(response.body);
          if (data.isNotEmpty) {
            lat = double.tryParse(data[0]['lat'].toString()) ?? lat;
            lng = double.tryParse(data[0]['lon'].toString()) ?? lng;
          }
        }
      } catch (e) {
        // Fallback
      }
    }

    final newJob = JobBooking(
      id: 'job_${DateTime.now().millisecondsSinceEpoch}',
      customerId: cust.id,
      customerName: cust.name,
      customerPhone: cust.phone,
      customerAddress: address.isNotEmpty ? address : cust.address,
      customerLat: lat,
      customerLng: lng,
      workCategory: workCategory,
      title: title,
      workDetails: workDetails,
      hourlyRate: hourlyRate,
      estimatedHours: estimatedHours,
      workersNeeded: workersNeeded,
      status: 'Pending',
      createdAt: DateTime.now().toString().split('.').first,
    );

    _jobs.insert(0, newJob);
    notifyListeners();
    await _supabaseService.saveJob(newJob);
  }

  // Cancel job request with reason and permanent deletion from Supabase
  Future<void> cancelJob(String jobId, String reason) async {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      _jobs.removeAt(index);
      notifyListeners();
      await _supabaseService.deleteJob(jobId);
    }
  }

  // Worker accepts job (triggers sound & haptic alerts, and adds notification)
  Future<void> acceptJob(String jobId, WorkerModel worker) async {
    // Sound & Haptic alerts when a worker accepts a job request
    try {
      await HapticFeedback.vibrate();
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      // Ignore if unsupported
    }

    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      final existing = _jobs[index];
      _jobs[index] = JobBooking(
        id: existing.id,
        customerId: existing.customerId,
        customerName: existing.customerName,
        customerPhone: existing.customerPhone,
        customerAddress: existing.customerAddress,
        customerLat: existing.customerLat,
        customerLng: existing.customerLng,
        workCategory: existing.workCategory,
        title: existing.title,
        workDetails: existing.workDetails,
        hourlyRate: existing.hourlyRate,
        estimatedHours: existing.estimatedHours,
        workersNeeded: existing.workersNeeded,
        status: 'Accepted',
        assignedWorkerId: worker.id,
        assignedWorkerName: worker.name,
        createdAt: existing.createdAt,
      );

      // Create notification for customer
      final notif = NotificationModel(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        userId: existing.customerId,
        title: 'Worker Accepted Your Job! 🎉',
        message: '${worker.name} (${worker.workCategory}) has accepted your job "${existing.title}".',
        isRead: false,
        createdAt: DateTime.now().toString().split('.').first,
      );
      _notifications.insert(0, notif);
      await _supabaseService.saveNotification(notif);

      notifyListeners();
      await _supabaseService.updateJobStatus(
        jobId,
        'Accepted',
        workerId: worker.id,
        workerName: worker.name,
      );
    }
  }

  // Complete job
  Future<void> completeJob(String jobId) async {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      final existing = _jobs[index];
      _jobs[index] = JobBooking(
        id: existing.id,
        customerId: existing.customerId,
        customerName: existing.customerName,
        customerPhone: existing.customerPhone,
        customerAddress: existing.customerAddress,
        customerLat: existing.customerLat,
        customerLng: existing.customerLng,
        workCategory: existing.workCategory,
        title: existing.title,
        workDetails: existing.workDetails,
        hourlyRate: existing.hourlyRate,
        estimatedHours: existing.estimatedHours,
        workersNeeded: existing.workersNeeded,
        status: 'Completed',
        assignedWorkerId: existing.assignedWorkerId,
        assignedWorkerName: existing.assignedWorkerName,
        createdAt: existing.createdAt,
      );

      // Create notification for customer
      final notif = NotificationModel(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        userId: existing.customerId,
        title: 'Job Completed! ✅',
        message: 'Your job "${existing.title}" has been marked as completed by ${existing.assignedWorkerName ?? 'Worker'}.',
        isRead: false,
        createdAt: DateTime.now().toString().split('.').first,
      );
      _notifications.insert(0, notif);
      await _supabaseService.saveNotification(notif);

      notifyListeners();
      await _supabaseService.updateJobStatus(jobId, 'Completed');
    }
  }

  Future<void> markNotificationAsRead(String notifId) async {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      await _supabaseService.markNotificationAsRead(notifId);
    }
  }
}
