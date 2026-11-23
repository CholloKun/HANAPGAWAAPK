import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../widgets/interactive_map_widget.dart';
import 'job_detail_screen.dart';
import 'login_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final DataService _dataService = DataService();

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
    final worker = _dataService.currentWorker ?? _dataService.workers.first;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Hanap Gawa — ${worker.name.split(' ').first} (Pro)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
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
              Tab(icon: Icon(Icons.map), text: 'Job Map Feed'),
              Tab(icon: Icon(Icons.list_alt), text: 'Available Jobs'),
              Tab(icon: Icon(Icons.verified), text: 'My Credentials'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Map Feed of Customer Locations in Need with Hourly Rates
            _buildMapFeedTab(maroonColor, worker),

            // TAB 2: List of Customer Job Requests
            _buildJobListTab(maroonColor, worker),

            // TAB 3: Worker Credentials & Verified Documents
            _buildCredentialsTab(maroonColor, worker),
          ],
        ),
      ),
    );
  }

  // TAB 1: Map Feed
  Widget _buildMapFeedTab(Color maroonColor, WorkerModel worker) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Banner Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: maroonColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: maroonColor.withAlpha(75)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: maroonColor, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Specialty: ${worker.workCategory} • ₱${worker.hourlyRate.toStringAsFixed(0)}/hr',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: maroonColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Map shows customer locations in need with money rate per hour.',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          InteractiveMapWidget(
            jobs: _dataService.jobs,
            workers: _dataService.workers,
            height: 440,
          ),
        ],
      ),
    );
  }

  // TAB 2: Job List
  Widget _buildJobListTab(Color maroonColor, WorkerModel worker) {
    final jobs = _dataService.jobs;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        final isAssignedToMe = job.assignedWorkerId == worker.id;

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: maroonColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        job.workCategory,
                        style: TextStyle(
                          color: maroonColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[800],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₱${job.hourlyRate.toStringAsFixed(0)} / hr',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Text(
                  job.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Customer: ${job.customerName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                Row(
                  children: [
                    Icon(Icons.location_on, color: maroonColor, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.customerAddress,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Work Details: ${job.workDetails}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Est. Total: ₱${job.estimatedTotal.toStringAsFixed(0)} (${job.estimatedHours} hrs)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: maroonColor,
                      ),
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAssignedToMe ? Colors.green : maroonColor,
                      ),
                      onPressed: () {
                        if (job.status == 'Pending') {
                          _dataService.acceptJob(job.id, worker);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Accepted Job "${job.title}"! Customer notified.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailScreen(job: job),
                            ),
                          );
                        }
                      },
                      child: Text(
                        job.status == 'Pending'
                            ? 'ACCEPT JOB'
                            : (isAssignedToMe ? 'MY JOB (VIEW)' : 'VIEW DETAILS'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 3: Worker Credentials & Verified Documents
  Widget _buildCredentialsTab(Color maroonColor, WorkerModel worker) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: maroonColor,
                        child: Text(
                          worker.name.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              worker.workCategory,
                              style: TextStyle(
                                color: maroonColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Rate: ₱${worker.hourlyRate.toStringAsFixed(0)} / hour',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  Text(
                    'VERIFIED WORKER CREDENTIALS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: maroonColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildCredentialRow(
                    Icons.badge,
                    'Working Permit No.',
                    worker.workingPermitNo,
                  ),
                  const SizedBox(height: 10),

                  _buildCredentialRow(
                    Icons.card_membership,
                    'National Certificate (NC II / TESDA)',
                    worker.nationalCertificateNo,
                  ),
                  const SizedBox(height: 10),

                  _buildCredentialRow(
                    Icons.description,
                    'Proficiency Proof Documents',
                    worker.proficiencyProof,
                  ),
                  const SizedBox(height: 10),

                  _buildCredentialRow(
                    Icons.phone,
                    'Contact Phone',
                    worker.phone,
                  ),
                  const SizedBox(height: 10),

                  _buildCredentialRow(
                    Icons.home,
                    'Address Location',
                    worker.address,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(IconData icon, String label, String value) {
    const maroonColor = Color(0xFF800000);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: maroonColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
