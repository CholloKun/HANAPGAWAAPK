import 'package:flutter/material.dart';
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

  // Sync jobs from Supabase on startup
  Future<void> _syncWithSupabase() async {
    final remoteJobs = await _supabaseService.fetchJobs();
    if (remoteJobs.isNotEmpty) {
      _jobs.clear();
      _jobs.addAll(remoteJobs);
      notifyListeners();
    }
  }

  // Sample Workers with proficiency documents & rates
  final List<WorkerModel> _workers = [
    WorkerModel(
      id: 'w1',
      name: 'Mang Juan dela Cruz',
      email: 'juan.carpentry@gmail.com',
      phone: '0917-555-1234',
      address: 'Sampaloc, Manila',
      workCategory: 'Carpentry',
      hourlyRate: 300.0,
      workingPermitNo: 'PERMIT-MNL-2024-8842',
      nationalCertificateNo: 'TESDA-NC2-CARP-99120',
      proficiencyProof: 'TESDA NC II Carpentry & Building Maintenance Certificate',
      rating: 4.9,
      completedJobs: 48,
      isAvailable: true,
      latitude: 14.6080,
      longitude: 120.9920,
    ),
    WorkerModel(
      id: 'w2',
      name: 'Ramon "Master Plumber" Santos',
      email: 'ramon.plumbing@gmail.com',
      phone: '0918-777-5678',
      address: 'Quezon City, Metro Manila',
      workCategory: 'Water Repairman / Plumbing',
      hourlyRate: 350.0,
      workingPermitNo: 'PERMIT-QC-2024-1102',
      nationalCertificateNo: 'TESDA-NC2-PLUMB-44810',
      proficiencyProof: 'Licensed Master Plumber & TESDA NC II Plumbing Certificate',
      rating: 4.8,
      completedJobs: 65,
      isAvailable: true,
      latitude: 14.6200,
      longitude: 121.0000,
    ),
    WorkerModel(
      id: 'w3',
      name: 'Engr. Joey Sparks (Electrician)',
      email: 'joey.electric@gmail.com',
      phone: '0920-333-4411',
      address: 'Makati City',
      workCategory: 'Electrical',
      hourlyRate: 400.0,
      workingPermitNo: 'PERMIT-MKT-2024-3091',
      nationalCertificateNo: 'TESDA-NC3-ELEC-77123',
      proficiencyProof: 'TESDA NC III Electrical Installation & Maintenance Certificate',
      rating: 5.0,
      completedJobs: 82,
      isAvailable: true,
      latitude: 14.5547,
      longitude: 121.0244,
    ),
    WorkerModel(
      id: 'w4',
      name: 'Cardo Dalisay (Mason & Tiler)',
      email: 'cardo.masonry@gmail.com',
      phone: '0999-111-2233',
      address: 'Mandaluyong City',
      workCategory: 'Masonry & Tiling',
      hourlyRate: 320.0,
      workingPermitNo: 'PERMIT-MDL-2024-0044',
      nationalCertificateNo: 'TESDA-NC2-MASON-55214',
      proficiencyProof: 'TESDA NC II Tile Setting & Construction Permit',
      rating: 4.7,
      completedJobs: 34,
      isAvailable: true,
      latitude: 14.5794,
      longitude: 121.0359,
    ),
    WorkerModel(
      id: 'w5',
      name: 'Elena Rostro (Cooling Tech)',
      email: 'elena.aircon@gmail.com',
      phone: '0915-888-9900',
      address: 'Pasig City',
      workCategory: 'Appliance Repair',
      hourlyRate: 380.0,
      workingPermitNo: 'PERMIT-PSG-2024-9122',
      nationalCertificateNo: 'TESDA-NC2-HVAC-12984',
      proficiencyProof: 'HVAC & Refrigeration Certified Technician (TESDA NC II)',
      rating: 4.9,
      completedJobs: 51,
      isAvailable: true,
      latitude: 14.5764,
      longitude: 121.0851,
    ),
  ];

  // Job Bookings List
  final List<JobBooking> _jobs = [
    JobBooking(
      id: 'job-101',
      customerId: 'c1',
      customerName: 'Maria Clara Santos',
      customerPhone: '0917-123-9988',
      customerAddress: '123 España Blvd, Sampaloc, Manila',
      customerLat: 14.6050,
      customerLng: 120.9900,
      workCategory: 'Water Repairman / Plumbing',
      title: 'Emergency Leaking Pipe Repair under Kitchen Sink',
      workDetails: 'Main kitchen pipe broke and leaking water heavily onto floor. Needs urgent repair, replacement of PVC connectors, and sealant application.',
      hourlyRate: 350.0,
      estimatedHours: 3.0,
      status: 'Pending',
      createdAt: '2025-02-23 09:30 AM',
    ),
    JobBooking(
      id: 'job-102',
      customerId: 'c2',
      customerName: 'Pedro Penduko',
      customerPhone: '0928-444-1122',
      customerAddress: '45 Katipunan Ave, Loyola Heights, Quezon City',
      customerLat: 14.6400,
      customerLng: 121.0700,
      workCategory: 'Carpentry',
      title: 'Wooden Cabinet & Door Hinge Repair',
      workDetails: 'Custom wooden kitchen cabinet doors sagging, alignment adjustment needed, plus repairing 2 bedroom doors that catch on the floor.',
      hourlyRate: 300.0,
      estimatedHours: 4.0,
      status: 'Pending',
      createdAt: '2025-02-23 10:15 AM',
    ),
    JobBooking(
      id: 'job-103',
      customerId: 'c3',
      customerName: 'Ana Patricia Non',
      customerPhone: '0919-888-3344',
      customerAddress: '78 Ayala Ave, Bel-Air, Makati City',
      customerLat: 14.5580,
      customerLng: 121.0200,
      workCategory: 'Electrical',
      title: 'Main Switch Board Breaker Tripping & Socket Installation',
      workDetails: 'Air conditioner outlet keeps tripping circuit breaker when turned on. Need licensed electrician to inspect breaker box and install dedicated 20A outlet line.',
      hourlyRate: 400.0,
      estimatedHours: 2.5,
      status: 'Accepted',
      assignedWorkerId: 'w3',
      assignedWorkerName: 'Engr. Joey Sparks (Electrician)',
      createdAt: '2025-02-22 04:45 PM',
    ),
    JobBooking(
      id: 'job-104',
      customerId: 'c4',
      customerName: 'Mang Benning',
      customerPhone: '0908-777-6655',
      customerAddress: '99 Shaw Blvd, Highway Hills, Mandaluyong',
      customerLat: 14.5810,
      customerLng: 121.0400,
      workCategory: 'Appliance Repair',
      title: 'Split-Type Aircon Deep Cleaning & Freon Recharge',
      workDetails: '2 HP split type Inverter AC unit in master bedroom not cooling effectively and dripping water. Needs thorough chemical coil washing and gas level check.',
      hourlyRate: 380.0,
      estimatedHours: 2.0,
      status: 'Pending',
      createdAt: '2025-02-23 11:00 AM',
    ),
  ];

  List<WorkerModel> get workers => List.unmodifiable(_workers);
  List<JobBooking> get jobs => List.unmodifiable(_jobs);

  // Filter workers by category
  List<WorkerModel> getWorkersByCategory(String category) {
    if (category == 'All') return _workers;
    return _workers.where((w) => w.workCategory == category).toList();
  }

  // Set default logged in user for testing/initial state
  void setLoggedInCustomer(CustomerModel customer) {
    _currentUserRole = UserRole.customer;
    _currentCustomer = customer;
    _currentWorker = null;
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
    notifyListeners();
  }

  // Register Customer
  CustomerModel registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String birthday,
    required String address,
  }) {
    final newCustomer = CustomerModel(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      birthday: birthday,
      address: address,
      latitude: 14.5995 + (DateTime.now().millisecond % 50) * 0.001,
      longitude: 120.9842 + (DateTime.now().millisecond % 50) * 0.001,
    );
    setLoggedInCustomer(newCustomer);
    _supabaseService.saveCustomer(newCustomer);
    return newCustomer;
  }

  // Register Worker
  WorkerModel registerWorker({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String workCategory,
    required double hourlyRate,
    required String workingPermitNo,
    required String nationalCertificateNo,
    required String proficiencyProof,
  }) {
    final newWorker = WorkerModel(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      address: address,
      workCategory: workCategory,
      hourlyRate: hourlyRate,
      workingPermitNo: workingPermitNo,
      nationalCertificateNo: nationalCertificateNo,
      proficiencyProof: proficiencyProof,
      latitude: 14.6000 + (DateTime.now().millisecond % 40) * 0.001,
      longitude: 120.9850 + (DateTime.now().millisecond % 40) * 0.001,
    );
    _workers.add(newWorker);
    setLoggedInWorker(newWorker);
    _supabaseService.saveWorker(newWorker);
    return newWorker;
  }

  // Add Job Booking from Customer
  void addJobBooking({
    required String title,
    required String workCategory,
    required String workDetails,
    required double hourlyRate,
    required double estimatedHours,
    required String address,
  }) {
    final cust = _currentCustomer ??
        CustomerModel(
          id: 'c_default',
          name: 'Juan Dela Cruz',
          email: 'user@hanapgawa.com',
          phone: '0917-000-1111',
          birthday: '1995-05-15',
          address: address.isNotEmpty ? address : 'Sampaloc, Manila',
        );

    final newJob = JobBooking(
      id: 'job_${DateTime.now().millisecondsSinceEpoch}',
      customerId: cust.id,
      customerName: cust.name,
      customerPhone: cust.phone,
      customerAddress: address.isNotEmpty ? address : cust.address,
      customerLat: cust.latitude,
      customerLng: cust.longitude,
      workCategory: workCategory,
      title: title,
      workDetails: workDetails,
      hourlyRate: hourlyRate,
      estimatedHours: estimatedHours,
      status: 'Pending',
      createdAt: DateTime.now().toString().split('.').first,
    );

    _jobs.insert(0, newJob);
    notifyListeners();
    _supabaseService.saveJob(newJob);
  }

  // Worker accepts job
  void acceptJob(String jobId, WorkerModel worker) {
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
        status: 'Accepted',
        assignedWorkerId: worker.id,
        assignedWorkerName: worker.name,
        createdAt: existing.createdAt,
      );
      notifyListeners();
      _supabaseService.updateJobStatus(
        jobId,
        'Accepted',
        workerId: worker.id,
        workerName: worker.name,
      );
    }
  }

  // Complete job
  void completeJob(String jobId) {
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
        status: 'Completed',
        assignedWorkerId: existing.assignedWorkerId,
        assignedWorkerName: existing.assignedWorkerName,
        createdAt: existing.createdAt,
      );
      notifyListeners();
      _supabaseService.updateJobStatus(jobId, 'Completed');
    }
  }
}
