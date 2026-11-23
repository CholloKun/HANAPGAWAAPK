import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Supabase Credentials
  static const String supabaseUrl = 'https://ngbzzihxpvfswzjnugbc.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nYnp6aWh4cHZmc3d6am51Z2JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUwNTkyMTYsImV4cCI6MjExMDYzNTIxNn0.PLk9SHptlaT5yP1BNv7ZM4O-TPFznzwalvEJYuKOVbM';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
      _instance._isInitialized = true;
      if (kDebugMode) {
        print('Supabase initialized successfully for Hanap Gawa.');
      }
      await _instance._testTableConnection();
    } catch (e) {
      if (kDebugMode) {
        print('Supabase initialization warning (running in offline mode): $e');
      }
    }
  }

  Future<void> _testTableConnection() async {
    if (!_isInitialized || client == null) return;
    try {
      final res = await client!.from('customers').select('id').limit(1);
      if (kDebugMode) {
        print('Supabase DB Connected! `customers` table check passed: $res');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase DB Connection Warning: Could not query `customers` table. Make sure supabase_schema.sql has been run in Supabase SQL Editor: $e');
      }
    }
  }

  // --- SQL DDL Schema for Supabase SQL Editor ---
  static const String sqlSchemaScript = '''
-- 1. Create Customers Table
CREATE TABLE IF NOT EXISTS public.customers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    birthday TEXT,
    address TEXT,
    latitude DOUBLE PRECISION DEFAULT 14.5995,
    longitude DOUBLE PRECISION DEFAULT 120.9842,
    profile_image_path TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create Workers Table with Credentials & Permits
CREATE TABLE IF NOT EXISTS public.workers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    address TEXT,
    work_category TEXT NOT NULL,
    hourly_rate DOUBLE PRECISION NOT NULL,
    working_permit_no TEXT NOT NULL,
    national_certificate_no TEXT NOT NULL,
    proficiency_proof TEXT NOT NULL,
    rating DOUBLE PRECISION DEFAULT 5.0,
    completed_jobs INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT true,
    latitude DOUBLE PRECISION DEFAULT 14.6010,
    longitude DOUBLE PRECISION DEFAULT 120.9860,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Create Job Bookings Table
CREATE TABLE IF NOT EXISTS public.job_bookings (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    customer_address TEXT NOT NULL,
    customer_lat DOUBLE PRECISION DEFAULT 14.5995,
    customer_lng DOUBLE PRECISION DEFAULT 120.9842,
    work_category TEXT NOT NULL,
    title TEXT NOT NULL,
    work_details TEXT NOT NULL,
    hourly_rate DOUBLE PRECISION NOT NULL,
    estimated_hours DOUBLE PRECISION DEFAULT 2.0,
    workers_needed INTEGER DEFAULT 1,
    status TEXT DEFAULT 'Pending',
    assigned_worker_id TEXT,
    assigned_worker_name TEXT,
    cancellation_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Create Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
''';

  // --- FETCH JOBS FROM SUPABASE ---
  Future<List<JobBooking>> fetchJobs({String? customerId}) async {
    if (!_isInitialized || client == null) return [];
    try {
      var query = client!.from('job_bookings').select();
      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }
      final response = await query.order('created_at', ascending: false);
      final List data = response as List;
      return data.map((json) => JobBooking.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching jobs from Supabase: $e');
      return [];
    }
  }

  // --- FETCH WORKERS FROM SUPABASE ---
  Future<List<WorkerModel>> fetchWorkers() async {
    if (!_isInitialized || client == null) return [];
    try {
      final response = await client!
          .from('workers')
          .select()
          .order('created_at', ascending: false);
      final List data = response as List;
      return data.map((json) => WorkerModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching workers from Supabase: $e');
      return [];
    }
  }

  // --- FETCH CUSTOMERS FROM SUPABASE ---
  Future<List<CustomerModel>> fetchCustomers() async {
    if (!_isInitialized || client == null) return [];
    try {
      final response = await client!
          .from('customers')
          .select()
          .order('created_at', ascending: false);
      final List data = response as List;
      return data.map((json) => CustomerModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching customers from Supabase: $e');
      return [];
    }
  }

  // --- QUERY CUSTOMER BY EMAIL ---
  Future<CustomerModel?> getCustomerByEmail(String email) async {
    if (!_isInitialized || client == null) return null;
    try {
      final response = await client!
          .from('customers')
          .select()
          .eq('email', email)
          .maybeSingle();
      if (response != null) {
        return CustomerModel.fromJson(response);
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching customer by email from Supabase: $e');
    }
    return null;
  }

  // --- QUERY WORKER BY EMAIL ---
  Future<WorkerModel?> getWorkerByEmail(String email) async {
    if (!_isInitialized || client == null) return null;
    try {
      final response = await client!
          .from('workers')
          .select()
          .eq('email', email)
          .maybeSingle();
      if (response != null) {
        return WorkerModel.fromJson(response);
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching worker by email from Supabase: $e');
    }
    return null;
  }

  // --- SAVE / UPSERT JOB TO SUPABASE ---
  Future<bool> saveJob(JobBooking job) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('job_bookings').upsert(job.toJson());
      if (kDebugMode) print('Job ${job.id} saved to Supabase successfully.');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error inserting job to Supabase: $e');
      return false;
    }
  }

  // --- DELETE JOB FROM SUPABASE (Permanent Deletion) ---
  Future<bool> deleteJob(String jobId) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('job_bookings').delete().eq('id', jobId);
      if (kDebugMode) print('Job $jobId permanently deleted from Supabase.');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting job from Supabase: $e');
      return false;
    }
  }

  // --- UPDATE JOB STATUS ---
  Future<bool> updateJobStatus(
    String jobId,
    String status, {
    String? workerId,
    String? workerName,
  }) async {
    if (!_isInitialized || client == null) return false;
    try {
      final updates = <String, dynamic>{'status': status};
      if (workerId != null) updates['assigned_worker_id'] = workerId;
      if (workerName != null) updates['assigned_worker_name'] = workerName;

      await client!.from('job_bookings').update(updates).eq('id', jobId);
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating job in Supabase: $e');
      return false;
    }
  }

  // --- REGISTER / UPSERT WORKER TO SUPABASE ---
  Future<bool> saveWorker(WorkerModel worker) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('workers').upsert(worker.toJson());
      if (kDebugMode) print('Worker ${worker.id} saved to Supabase successfully.');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error inserting worker to Supabase: $e');
      return false;
    }
  }

  // --- REGISTER / UPSERT CUSTOMER TO SUPABASE ---
  Future<bool> saveCustomer(CustomerModel customer) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('customers').upsert(customer.toJson());
      if (kDebugMode) print('Customer ${customer.id} saved to Supabase successfully.');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error inserting customer to Supabase: $e');
      return false;
    }
  }

  // --- FETCH NOTIFICATIONS FROM SUPABASE ---
  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    if (!_isInitialized || client == null) return [];
    try {
      final response = await client!
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final List data = response as List;
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching notifications from Supabase: $e');
      return [];
    }
  }

  // --- SAVE NOTIFICATION TO SUPABASE ---
  Future<bool> saveNotification(NotificationModel notification) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('notifications').upsert(notification.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) print('Error saving notification to Supabase: $e');
      return false;
    }
  }

  // --- MARK NOTIFICATION AS READ ---
  Future<bool> markNotificationAsRead(String notificationId) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      if (kDebugMode) print('Error marking notification as read in Supabase: $e');
      return false;
    }
  }

  // --- SUPABASE AUTH METHODS ---
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized || client == null) return null;
    try {
      return await client!.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
    } catch (e) {
      if (kDebugMode) print('Supabase Auth SignUp error: $e');
      return null;
    }
  }

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized || client == null) return null;
    try {
      return await client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      if (kDebugMode) print('Supabase Auth SignIn error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    if (!_isInitialized || client == null) return;
    try {
      await client!.auth.signOut();
    } catch (e) {
      if (kDebugMode) print('Supabase Auth SignOut error: $e');
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      return true;
    } catch (e) {
      if (kDebugMode) print('Supabase Resend Verification error: $e');
      return false;
    }
  }

  Future<bool> isEmailConfirmed() async {
    if (!_isInitialized || client == null) return true;
    try {
      await client!.auth.refreshSession();
      final user = client!.auth.currentUser;
      if (user == null) return false;
      return user.emailConfirmedAt != null;
    } catch (e) {
      if (kDebugMode) print('Check email confirmation error: $e');
      return true;
    }
  }
}
