-- ============================================================
-- HANAP GAWA - SUPABASE DATABASE SCHEMA & SEED DATA
-- Run this script in your Supabase Dashboard SQL Editor (https://supabase.com/dashboard)
-- Project URL: https://ngbzzihxpvfswzjnugbc.supabase.co
-- ============================================================

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

-- Disable Row Level Security (RLS) for public access
ALTER TABLE public.customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.workers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_bookings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;

-- Add RLS Policies in case RLS is re-enabled on dashboard
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

-- ============================================================
-- SEED SAMPLE WORKERS
-- ============================================================
INSERT INTO public.workers (id, name, email, phone, address, work_category, hourly_rate, working_permit_no, national_certificate_no, proficiency_proof, rating, completed_jobs, is_available, latitude, longitude)
VALUES
('w1', 'Mang Juan dela Cruz', 'juan.carpentry@gmail.com', '0917-555-1234', 'Sampaloc, Manila', 'Carpentry', 300.0, 'PERMIT-MNL-2024-8842', 'TESDA-NC2-CARP-99120', 'TESDA NC II Carpentry & Building Maintenance Certificate', 4.9, 48, true, 14.6080, 120.9920),
('w2', 'Ramon "Master Plumber" Santos', 'ramon.plumbing@gmail.com', '0918-777-5678', 'Quezon City, Metro Manila', 'Water Repairman / Plumbing', 350.0, 'PERMIT-QC-2024-1102', 'TESDA-NC2-PLUMB-44810', 'Licensed Master Plumber & TESDA NC II Plumbing Certificate', 4.8, 65, true, 14.6200, 121.0000),
('w3', 'Engr. Joey Sparks (Electrician)', 'joey.electric@gmail.com', '0920-333-4411', 'Makati City', 'Electrical', 400.0, 'PERMIT-MKT-2024-3091', 'TESDA-NC3-ELEC-77123', 'TESDA NC III Electrical Installation & Maintenance Certificate', 5.0, 82, true, 14.5547, 121.0244),
('w4', 'Cardo Dalisay (Mason & Tiler)', 'cardo.masonry@gmail.com', '0999-111-2233', 'Mandaluyong City', 'Masonry & Tiling', 320.0, 'PERMIT-MDL-2024-0044', 'TESDA-NC2-MASON-55214', 'TESDA NC II Tile Setting & Construction Permit', 4.7, 34, true, 14.5794, 121.0359),
('w5', 'Elena Rostro (Cooling Tech)', 'elena.aircon@gmail.com', '0915-888-9900', 'Pasig City', 'Appliance Repair', 380.0, 'PERMIT-PSG-2024-9122', 'TESDA-NC2-HVAC-12984', 'HVAC & Refrigeration Certified Technician (TESDA NC II)', 4.9, 51, true, 14.5764, 121.0851)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- SEED SAMPLE JOB BOOKINGS
-- ============================================================
INSERT INTO public.job_bookings (id, customer_id, customer_name, customer_phone, customer_address, customer_lat, customer_lng, work_category, title, work_details, hourly_rate, estimated_hours, workers_needed, status, created_at)
VALUES
('job-101', 'c1', 'Maria Clara Santos', '0917-123-9988', '123 España Blvd, Sampaloc, Manila', 14.6050, 120.9900, 'Water Repairman / Plumbing', 'Emergency Leaking Pipe Repair under Kitchen Sink', 'Main kitchen pipe broke and leaking water heavily onto floor. Needs urgent repair, replacement of PVC connectors, and sealant application.', 350.0, 3.0, 1, 'Pending', NOW()),
('job-102', 'c2', 'Pedro Penduko', '0928-444-1122', '45 Katipunan Ave, Loyola Heights, Quezon City', 14.6400, 121.0700, 'Carpentry', 'Wooden Cabinet & Door Hinge Repair', 'Custom wooden kitchen cabinet doors sagging, alignment adjustment needed, plus repairing 2 bedroom doors that catch on the floor.', 300.0, 4.0, 1, 'Pending', NOW()),
('job-103', 'c3', 'Ana Patricia Non', '0919-888-3344', '78 Ayala Ave, Bel-Air, Makati City', 14.5580, 121.0200, 'Electrical', 'Main Switch Board Breaker Tripping & Socket Installation', 'Air conditioner outlet keeps tripping circuit breaker when turned on. Need licensed electrician to inspect breaker box and install dedicated 20A outlet line.', 400.0, 2.5, 1, 'Accepted', NOW())
ON CONFLICT (id) DO NOTHING;
