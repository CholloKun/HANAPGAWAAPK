import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../widgets/interactive_map_widget.dart';
import 'job_detail_screen.dart';
import 'post_job_screen.dart';
import 'login_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final DataService _dataService = DataService();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);
    final customer = _dataService.currentCustomer ??
        CustomerModel(
          id: 'c_guest',
          name: 'Juan Dela Cruz',
          email: 'juan@gmail.com',
          phone: '0917-111-2233',
          birthday: '1996-01-01',
          address: 'Sampaloc, Manila',
        );

    final filteredWorkers = _dataService.getWorkersByCategory(_selectedCategory);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Hanap Gawa — Customer',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                _dataService.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            tabs: [
              Tab(icon: Icon(Icons.search), text: 'Find Workers'),
              Tab(icon: Icon(Icons.map), text: 'Map View'),
              Tab(icon: Icon(Icons.history), text: 'My Bookings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Search & Browse Workers by Category
            _buildWorkersTab(maroonColor, filteredWorkers),

            // TAB 2: Interactive Location Map with Money Rates & Details
            _buildMapTab(maroonColor),

            // TAB 3: Customer Job Bookings Status
            _buildBookingsTab(maroonColor),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: maroonColor,
          icon: const Icon(Icons.add_task, color: Colors.white),
          label: const Text(
            'Post Job Request',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PostJobScreen()),
            );
          },
        ),
      ),
    );
  }

  // TAB 1: Browse Skilled Workers by Category & Credentials
  Widget _buildWorkersTab(Color maroonColor, List<WorkerModel> workersList) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Banner Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF800000), Color(0xFF5A0000)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.handyman, color: Colors.amber, size: 36),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Certified Workers Near You',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Carpentry, Water Repair, Electrical & More with Verified NC Certificates & Permits.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Select Work Specialty:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: maroonColor,
            ),
          ),
          const SizedBox(height: 10),

          // Categories Horizontal Selector
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('All', 'All Workers'),
                ...WorkCategory.categories.map((c) {
                  return _buildCategoryChip(c.title, c.title);
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Skilled Workers (${workersList.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                _selectedCategory,
                style: TextStyle(color: maroonColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Worker Cards List
          if (workersList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text('No workers currently registered under this category.'),
              ),
            )
          else
            ...workersList.map((worker) => _buildWorkerCard(maroonColor, worker)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    const maroonColor = Color(0xFF800000);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : maroonColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        selectedColor: maroonColor,
        backgroundColor: maroonColor.withOpacity(0.08),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
      ),
    );
  }

  Widget _buildWorkerCard(Color maroonColor, WorkerModel worker) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: maroonColor,
                  child: Text(
                    worker.name.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              worker.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[800],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '₱${worker.hourlyRate.toStringAsFixed(0)}/hr',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${worker.workCategory} • ${worker.address}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                            ' ${worker.rating} (${worker.completedJobs} jobs done)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Credentials & Permit Info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.blue, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'NC Certificate: ${worker.nationalCertificateNo}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.badge, color: maroonColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Working Permit: ${worker.workingPermitNo}',
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Book Worker Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostJobScreen(
                        preselectedCategory: worker.workCategory,
                        preselectedWorkerName: worker.name,
                        suggestedRate: worker.hourlyRate,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                label: Text(
                  'Book ${worker.name.split(' ').first} (₱${worker.hourlyRate.toStringAsFixed(0)}/hr)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: Map Tab showing customer locations, hourly rate badges & details
  Widget _buildMapTab(Color maroonColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map, color: maroonColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Map of Posted Customer Job Requests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: maroonColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap on any location pin to see hourly money rate (₱/hr) and work details.',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 12),

          // Custom Map Widget
          InteractiveMapWidget(
            jobs: _dataService.jobs,
            workers: _dataService.workers,
            height: 420,
          ),
        ],
      ),
    );
  }

  // TAB 3: Customer Job Bookings Status
  Widget _buildBookingsTab(Color maroonColor) {
    final jobs = _dataService.jobs;

    if (jobs.isEmpty) {
      return const Center(
        child: Text('No job bookings posted yet. Tap + to post a job!'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        final isAccepted = job.status == 'Accepted';
        final isCompleted = job.status == 'Completed';

        Color statusColor = Colors.orange;
        if (isAccepted) statusColor = Colors.blue;
        if (isCompleted) statusColor = Colors.green;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: maroonColor,
              child: const Icon(Icons.work, color: Colors.white, size: 20),
            ),
            title: Text(
              job.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${job.workCategory}'),
                Text('Rate: ₱${job.hourlyRate.toStringAsFixed(0)}/hr • Est: ₱${job.estimatedTotal.toStringAsFixed(0)}'),
              ],
            ),
            trailing: Chip(
              label: Text(
                job.status,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              backgroundColor: statusColor,
            ),
            children: [
              Container(
                color: Colors.grey[50],
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Work Description:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: maroonColor),
                    ),
                    const SizedBox(height: 4),
                    Text(job.workDetails, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 10),
                    Text(
                      'Job Location: ${job.customerAddress}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    if (job.assignedWorkerName != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Assigned Worker: ${job.assignedWorkerName}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: maroonColor),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobDetailScreen(job: job),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map, color: Colors.white, size: 16),
                      label: const Text(
                        'View Location on Map & Details',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
