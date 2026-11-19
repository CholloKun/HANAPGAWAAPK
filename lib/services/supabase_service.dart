import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Supabase Credentials
  static const String supabaseUrl = 'https://gyhdueaabwulqnipnqjc.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5aGR1ZWFhYnd1bHFuaXBucWpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM5NTQzMDIsImV4cCI6MjEwOTUzMDMwMn0.Kueztx9RLhOqJRmF4gbqGq_47-iSaFKQqRzwYEd-BGY';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _instance._isInitialized = true;
      if (kDebugMode) {
        print('Supabase initialized successfully for Hanap Gawa.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase initialization warning (running in offline mode): $e');
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
    status TEXT DEFAULT 'Pending',
    assigned_worker_id TEXT,
    assigned_worker_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
''';

  // --- FETCH JOBS FROM SUPABASE ---
  Future<List<JobBooking>> fetchJobs() async {
    if (!_isInitialized || client == null) return [];
    try {
      final response = await client!
          .from('job_bookings')
          .select()
          .order('created_at', ascending: false);
      final List data = response as List;
      return data.map((json) => JobBooking.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching jobs from Supabase: $e');
      return [];
    }
  }

  // --- INSERT JOB TO SUPABASE ---
  Future<bool> saveJob(JobBooking job) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('job_bookings').insert(job.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) print('Error inserting job to Supabase: $e');
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

  // --- REGISTER WORKER TO SUPABASE ---
  Future<bool> saveWorker(WorkerModel worker) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('workers').insert(worker.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) print('Error inserting worker to Supabase: $e');
      return false;
    }
  }

  // --- REGISTER CUSTOMER TO SUPABASE ---
  Future<bool> saveCustomer(CustomerModel customer) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('customers').insert(customer.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) print('Error inserting customer to Supabase: $e');
      return false;
    }
  }
}
