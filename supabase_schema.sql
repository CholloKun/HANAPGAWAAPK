-- ============================================================
-- HANAP GAWA - COMPLETE SUPABASE DATABASE SCHEMA
-- Copy & paste this script into your Supabase Dashboard SQL Editor (https://supabase.com/dashboard)
-- ============================================================

-- 1. Create Customers Table
CREATE TABLE IF NOT EXISTS public.customers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    birthday TEXT,
    address TEXT,
    latitude DOUBLE PRECISION DEFAULT 11.5606,
    longitude DOUBLE PRECISION DEFAULT 124.3986,
    profile_image_path TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create Workers Table with Credentials & Permits
CREATE TABLE IF NOT EXISTS public.workers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    birthday TEXT,
    address TEXT,
    work_category TEXT NOT NULL,
    hourly_rate DOUBLE PRECISION NOT NULL,
    working_permit_no TEXT NOT NULL,
    national_certificate_no TEXT NOT NULL,
    proficiency_proof TEXT NOT NULL,
    national_certificate_doc TEXT,
    working_permit_doc TEXT,
    rating DOUBLE PRECISION DEFAULT 5.0,
    completed_jobs INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT true,
    latitude DOUBLE PRECISION DEFAULT 11.5610,
    longitude DOUBLE PRECISION DEFAULT 124.3990,
    profile_image_path TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Create Job Bookings Table
CREATE TABLE IF NOT EXISTS public.job_bookings (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    customer_address TEXT NOT NULL,
    customer_lat DOUBLE PRECISION DEFAULT 11.5606,
    customer_lng DOUBLE PRECISION DEFAULT 124.3986,
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

-- Ensure all columns exist if tables were created previously
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS profile_image_path TEXT;
ALTER TABLE public.workers ADD COLUMN IF NOT EXISTS birthday TEXT;
ALTER TABLE public.workers ADD COLUMN IF NOT EXISTS national_certificate_doc TEXT;
ALTER TABLE public.workers ADD COLUMN IF NOT EXISTS working_permit_doc TEXT;
ALTER TABLE public.workers ADD COLUMN IF NOT EXISTS profile_image_path TEXT;
ALTER TABLE public.job_bookings ADD COLUMN IF NOT EXISTS workers_needed INTEGER DEFAULT 1;
ALTER TABLE public.job_bookings ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;

-- Enable Row Level Security (RLS) & Add Public Access Policies
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public access on customers" ON public.customers;
CREATE POLICY "Allow public access on customers" ON public.customers FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access on workers" ON public.workers;
CREATE POLICY "Allow public access on workers" ON public.workers FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access on job_bookings" ON public.job_bookings;
CREATE POLICY "Allow public access on job_bookings" ON public.job_bookings FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public access on notifications" ON public.notifications;
CREATE POLICY "Allow public access on notifications" ON public.notifications FOR ALL USING (true) WITH CHECK (true);
