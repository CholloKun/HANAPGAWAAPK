import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../widgets/interactive_map_widget.dart';
import '../widgets/location_picker_dialog.dart';
import 'job_detail_screen.dart';
import 'login_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> with SingleTickerProviderStateMixin {
  final DataService _dataService = DataService();
  int _previousJobCount = 0;
  late TabController _tabController;
  JobBooking? _selectedMapJob;

  late TextEditingController _wNameCtrl;
  late TextEditingController _wPhoneCtrl;
  late TextEditingController _wBirthdayCtrl;
  late TextEditingController _wAddressCtrl;
  late TextEditingController _wRateCtrl;
  late TextEditingController _wProficiencyProofCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dataService.addListener(_onStateChange);
    _previousJobCount = _dataService.jobs.length;
    _dataService.syncWithSupabase();
    _initWorkerProfileControllers();
  }

  void _initWorkerProfileControllers() {
    final worker = _dataService.currentWorker ?? (_dataService.workers.isNotEmpty ? _dataService.workers.first : null);
    _wNameCtrl = TextEditingController(text: worker?.name ?? '');
    _wPhoneCtrl = TextEditingController(text: worker?.phone ?? '');
    _wBirthdayCtrl = TextEditingController(text: worker?.birthday ?? '');
    _wAddressCtrl = TextEditingController(text: worker?.address ?? '');
    _wRateCtrl = TextEditingController(text: (worker?.hourlyRate ?? 350.0).toStringAsFixed(0));
    _wProficiencyProofCtrl = TextEditingController(text: worker?.proficiencyProof ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dataService.removeListener(_onStateChange);
    _wNameCtrl.dispose();
    _wPhoneCtrl.dispose();
    _wBirthdayCtrl.dispose();
    _wAddressCtrl.dispose();
    _wRateCtrl.dispose();
    _wProficiencyProofCtrl.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (!mounted) return;

    // Detect new incoming job requests
    final currentJobs = _dataService.jobs;
    if (currentJobs.length > _previousJobCount) {
      final newest = currentJobs.first;
      if (newest.status == 'Pending') {
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.heavyImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'New Job Request Posted! 🔔',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      Text(
                        'Customer ${newest.customerName} requested ${newest.workCategory} (${newest.customerAddress}).',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF800000),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
    _previousJobCount = currentJobs.length;
    setState(() {});
  }

  Future<void> _refreshEntirePage() async {
    await _dataService.syncWithSupabase();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const WorkerHomeScreen(),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  Future<void> _pickWorkerAvatar() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64String';

        await _dataService.updateWorkerProfile(profileImagePath: dataUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Worker profile picture updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error updating avatar: $e');
    }
  }

  Future<void> _pickWorkerDocument(bool isNcDoc) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64String';

        if (isNcDoc) {
          await _dataService.updateWorkerProfile(nationalCertificateDoc: dataUrl);
        } else {
          await _dataService.updateWorkerProfile(workingPermitDoc: dataUrl);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isNcDoc ? 'TESDA NC Certificate document updated!' : 'Working Permit document updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error updating document: $e');
    }
  }

  void _openWorkerNotifications(BuildContext context) {
    const maroonColor = Color(0xFF800000);
    final pendingJobs = _dataService.jobs.where((j) => j.status == 'Pending').toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active, color: maroonColor, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Worker Notifications',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: maroonColor),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: pendingJobs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 10),
                            Text('No pending job alerts right now', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: pendingJobs.length,
                        itemBuilder: (context, index) {
                          final job = pendingJobs[index];
                          return Card(
                            elevation: 3,
                            color: Colors.amber.shade50,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: maroonColor,
                                child: Icon(Icons.work, color: Colors.white, size: 20),
                              ),
                              title: Text(
                                job.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text('${job.customerName} • ${job.customerAddress}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                  const SizedBox(height: 2),
                                  Text('Rate: ₱${job.hourlyRate.toStringAsFixed(0)}/hr • ${job.estimatedHours} hrs', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: maroonColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                onPressed: () {
                                  Navigator.pop(modalContext);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
                                  );
                                },
                                child: const Text('VIEW', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openWorkerProfileModal(BuildContext context, WorkerModel worker) {
    const maroonColor = Color(0xFF800000);
    final updatedWorker = _dataService.currentWorker ?? worker;

    _wNameCtrl.text = updatedWorker.name;
    _wPhoneCtrl.text = updatedWorker.phone;
    _wBirthdayCtrl.text = updatedWorker.birthday;
    _wAddressCtrl.text = updatedWorker.address;
    _wRateCtrl.text = updatedWorker.hourlyRate.toStringAsFixed(0);
    _wProficiencyProofCtrl.text = updatedWorker.proficiencyProof;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Worker Profile & Contacts',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: maroonColor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    Stack(
                      children: [
                        _buildWorkerAvatarImage(updatedWorker.profileImagePath, radius: 50, fallbackInitial: updatedWorker.name),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: Colors.amber,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () async {
                                await _pickWorkerAvatar();
                                setModalState(() {});
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.camera_alt, color: Colors.black87, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _wNameCtrl,
                      decoration: _inputDecoration('Full Name', Icons.person_outline),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _wPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Contact Phone Number', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _wBirthdayCtrl,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(1995, 1, 1),
                          firstDate: DateTime(1930),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          setModalState(() {
                            _wBirthdayCtrl.text = formatted;
                          });
                        }
                      },
                      decoration: _inputDecoration('Date of Birth', Icons.cake_outlined),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _wAddressCtrl,
                      decoration: InputDecoration(
                        labelText: 'Complete Address',
                        prefixIcon: const Icon(Icons.home_outlined, color: maroonColor),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.map, color: maroonColor),
                          tooltip: 'Pick Location on Map',
                          onPressed: () async {
                            final selected = await LocationPickerDialog.show(
                              context,
                              initialAddress: _wAddressCtrl.text,
                            );
                            if (selected != null && selected.isNotEmpty) {
                              setModalState(() {
                                _wAddressCtrl.text = selected;
                              });
                            }
                          },
                        ),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _wRateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Hourly Rate (₱ / hr)', Icons.payments_outlined),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _wProficiencyProofCtrl,
                      maxLines: 2,
                      decoration: _inputDecoration('Proficiency Proof / Experience', Icons.description_outlined),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: maroonColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final rate = double.tryParse(_wRateCtrl.text.trim()) ?? updatedWorker.hourlyRate;
                          await _dataService.updateWorkerProfile(
                            name: _wNameCtrl.text.trim(),
                            phone: _wPhoneCtrl.text.trim(),
                            birthday: _wBirthdayCtrl.text.trim(),
                            address: _wAddressCtrl.text.trim(),
                            hourlyRate: rate,
                          );
                          if (mounted) {
                            Navigator.pop(modalContext);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Worker profile updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    const maroonColor = Color(0xFF800000);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: maroonColor),
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  Widget _buildWorkerAvatarImage(String? imagePath, {double radius = 22, String fallbackInitial = 'W'}) {
    const maroonColor = Color(0xFF800000);
    final isSmall = radius <= 25;
    final hasAvatar = imagePath != null && imagePath.isNotEmpty;

    if (hasAvatar) {
      if (imagePath.startsWith('data:image')) {
        try {
          final bytes = base64Decode(imagePath.split(',').last);
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (e) {}
      } else if (kIsWeb || imagePath.startsWith('http') || imagePath.startsWith('blob:') || imagePath.startsWith('assets/')) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.white,
          backgroundImage: NetworkImage(imagePath),
        );
      } else {
        try {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            backgroundImage: FileImage(File(imagePath)),
          );
        } catch (e) {}
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: isSmall ? Colors.white : maroonColor,
      child: Text(
        fallbackInitial.isNotEmpty ? fallbackInitial[0].toUpperCase() : 'W',
        style: TextStyle(
          color: isSmall ? maroonColor : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);
    final worker = _dataService.currentWorker ??
        WorkerModel(
          id: 'w_pro',
          name: 'Juan Dela Cruz',
          email: 'juan.carpentry@gmail.com',
          phone: '0917-555-1234',
          birthday: '1992-08-15',
          address: 'Naval Centro, Biliran, Philippines',
          workCategory: 'Carpentry',
          hourlyRate: 350.0,
          workingPermitNo: 'PERMIT-NAV-2024-8842',
          nationalCertificateNo: 'TESDA-NC2-CARP-99120',
          proficiencyProof: 'Licensed Carpentry Master & TESDA NC II Certified',
        );

    final pendingCount = _dataService.jobs.where((j) => j.status == 'Pending').length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: maroonColor,
          elevation: 0,
          toolbarHeight: 70,
          title: Row(
            children: [
              // Top Left Corner Worker Avatar
              Stack(
                children: [
                  _buildWorkerAvatarImage(worker.profileImagePath, radius: 22, fallbackInitial: worker.name),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.build, color: Colors.black87, size: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${worker.name.split(' ').first}! 🛠️',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Verified ${worker.workCategory} Pro',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Notifications Bell Icon with Unread Badge
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  tooltip: 'Job Alerts',
                  onPressed: () => _openWorkerNotifications(context),
                ),
                if (pendingCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Page',
              onPressed: _refreshEntirePage,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
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
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.amber,
            indicatorWeight: 3,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(
                icon: Icon(Icons.map_outlined),
                text: 'Job Map Feed',
              ),
              Tab(
                icon: Icon(Icons.assignment_outlined),
                text: 'Job Requests',
              ),
              Tab(
                icon: Icon(Icons.verified_user_outlined),
                text: 'Credentials & Profile',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: Map Feed of Customer Locations
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
            selectedJob: _selectedMapJob,
            height: 460,
          ),
        ],
      ),
    );
  }

  // TAB 2: Job List
  Widget _buildJobListTab(Color maroonColor, WorkerModel worker) {
    final jobs = _dataService.jobs;

    return RefreshIndicator(
      onRefresh: _refreshEntirePage,
      color: maroonColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  const SizedBox(height: 8),

                  Text(
                    job.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    'Customer: ${job.customerName}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Location: ${job.customerAddress}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    job.workDetails,
                    style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Est. Total: ₱${job.estimatedTotal.toStringAsFixed(0)} (${job.estimatedHours} hrs)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${job.workersNeeded} worker${job.workersNeeded > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: maroonColor,
                            side: BorderSide(color: maroonColor),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedMapJob = job;
                              _tabController.animateTo(0);
                            });
                          },
                          icon: Icon(Icons.map, size: 16, color: maroonColor),
                          label: const Text('SEE IN MAP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAssignedToMe ? Colors.green : maroonColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobDetailScreen(job: job),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility, color: Colors.white, size: 16),
                          label: Text(
                            job.status == 'Pending'
                                ? 'SEE DETAILS'
                                : (isAssignedToMe ? 'MY JOB (VIEW)' : 'SEE DETAILS'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  // TAB 3: Worker Credentials, Scanned Documents & Profile
  Widget _buildCredentialsTab(Color maroonColor, WorkerModel worker) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Card with Avatar Upload
          Card(
            elevation: 4,
            shadowColor: maroonColor.withAlpha(25),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      _buildWorkerAvatarImage(worker.profileImagePath, radius: 52, fallbackInitial: worker.name),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: Colors.amber,
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _pickWorkerAvatar,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.camera_alt, color: Colors.black87, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    worker.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: maroonColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Verified ${worker.workCategory} Specialist',
                      style: TextStyle(color: maroonColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hourly Rate: ₱${worker.hourlyRate.toStringAsFixed(0)} / hr',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: maroonColor,
                      side: BorderSide(color: maroonColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _pickWorkerAvatar,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Upload / Change Profile Picture', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openWorkerProfileModal(context, worker),
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text('Edit Profile & Contacts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Personal Details Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: maroonColor, size: 20),
                      const SizedBox(width: 8),
                      Text('Personal Information & Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: maroonColor)),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildCredentialRow(Icons.phone, 'Contact Phone Number', worker.phone),
                  const SizedBox(height: 12),
                  _buildCredentialRow(Icons.email, 'Email Address', worker.email),
                  const SizedBox(height: 12),
                  _buildCredentialRow(Icons.cake, 'Date of Birth (Birthday)', worker.birthday.isNotEmpty ? worker.birthday : 'Not provided'),
                  const SizedBox(height: 12),
                  _buildCredentialRow(Icons.home, 'Complete Address / Location', worker.address),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Verified Credentials & Scanned Documents Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user, color: maroonColor, size: 20),
                      const SizedBox(width: 8),
                      Text('Official Credentials & Scanned Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: maroonColor)),
                    ],
                  ),
                  const Divider(height: 20),

                  // Working Permit
                  _buildCredentialRow(Icons.badge, 'Working Permit No.', worker.workingPermitNo),
                  const SizedBox(height: 10),
                  _buildDocumentPreviewCard(
                    title: 'Scanned Working Permit / Gov ID Image',
                    docBase64: worker.workingPermitDoc,
                    onUpload: () => _pickWorkerDocument(false),
                  ),
                  const SizedBox(height: 20),

                  // TESDA NC Certificate
                  _buildCredentialRow(Icons.card_membership, 'TESDA National Certificate (NC II)', worker.nationalCertificateNo),
                  const SizedBox(height: 10),
                  _buildDocumentPreviewCard(
                    title: 'Scanned TESDA NC Certificate Image',
                    docBase64: worker.nationalCertificateDoc,
                    onUpload: () => _pickWorkerDocument(true),
                  ),
                  const SizedBox(height: 20),

                  // Proficiency Proof
                  _buildCredentialRow(Icons.description, 'Proficiency Proof & Experience Details', worker.proficiencyProof),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreviewCard({
    required String title,
    required String? docBase64,
    required VoidCallback onUpload,
  }) {
    const maroonColor = Color(0xFF800000);
    final hasDoc = docBase64 != null && docBase64.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasDoc ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasDoc ? Colors.green.shade300 : Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(hasDoc ? Icons.check_circle : Icons.warning_amber_rounded, color: hasDoc ? Colors.green[800] : Colors.amber[900], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: hasDoc ? Colors.green[800] : Colors.black87),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasDoc ? Colors.green[800] : maroonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onUpload,
                icon: Icon(hasDoc ? Icons.edit : Icons.upload_file, size: 14, color: Colors.white),
                label: Text(
                  hasDoc ? 'Change Doc' : 'Upload Image',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (hasDoc) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: docBase64.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(docBase64.split(',').last),
                        fit: BoxFit.cover,
                      )
                    : (docBase64.startsWith('http') || docBase64.startsWith('blob:')
                        ? Image.network(docBase64, fit: BoxFit.cover)
                        : Image.file(File(docBase64), fit: BoxFit.cover)),
              ),
            ),
          ],
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
