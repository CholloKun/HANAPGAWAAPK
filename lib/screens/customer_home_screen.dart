import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../widgets/interactive_map_widget.dart';
import '../widgets/location_picker_dialog.dart';
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
  String _bookingStatusFilter = 'All';

  // Profile controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _birthdayCtrl;
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onStateChange);
    _initProfileControllers();
  }

  void _initProfileControllers() {
    final customer = _dataService.currentCustomer;
    _nameCtrl = TextEditingController(text: customer?.name ?? '');
    _phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    _birthdayCtrl = TextEditingController(text: customer?.birthday ?? '');
    _addressCtrl = TextEditingController(text: customer?.address ?? '');
  }

  @override
  void dispose() {
    _dataService.removeListener(_onStateChange);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _birthdayCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) {
      final customer = _dataService.currentCustomer;
      if (customer != null) {
        if (_nameCtrl.text.isEmpty) _nameCtrl.text = customer.name;
        if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = customer.phone;
        if (_birthdayCtrl.text.isEmpty) _birthdayCtrl.text = customer.birthday;
        if (_addressCtrl.text.isEmpty) _addressCtrl.text = customer.address;
      }
      setState(() {});
    }
  }

  Future<void> _pickAvatarImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      _dataService.updateCustomerProfile(
        profileImagePath: pickedFile.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _birthdayCtrl.text = formatted;
      });
    }
  }

  void _openCustomerProfileModal(BuildContext context, CustomerModel customer) {
    const maroonColor = Color(0xFF800000);
    final updatedCustomer = _dataService.currentCustomer ?? customer;
    
    _nameCtrl.text = updatedCustomer.name;
    _phoneCtrl.text = updatedCustomer.phone;
    _birthdayCtrl.text = updatedCustomer.birthday;
    _addressCtrl.text = updatedCustomer.address;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentCust = _dataService.currentCustomer ?? updatedCustomer;
            final hasAvatar = currentCust.profileImagePath != null &&
                currentCust.profileImagePath!.isNotEmpty;

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
                    // Handle bar
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
                          'Customer Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: maroonColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Avatar Circle with Camera Badge
                    Stack(
                      children: [
                        _buildAvatarImage(updatedCustomer.profileImagePath, radius: 50, fallbackInitial: updatedCustomer.name),
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
                                await _pickAvatarImage();
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
                    const SizedBox(height: 12),

                    Text(
                      updatedCustomer.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: maroonColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Verified Customer Account',
                        style: TextStyle(
                          color: maroonColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: maroonColor,
                        side: const BorderSide(color: maroonColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await _pickAvatarImage();
                        setModalState(() {});
                      },
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text(
                        'Upload / Change Profile Picture',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Information Form
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration('Full Name', Icons.person_outline),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      initialValue: updatedCustomer.email,
                      readOnly: true,
                      decoration: _inputDecoration('Email Address (Account)', Icons.email_outlined),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _birthdayCtrl,
                      readOnly: true,
                      onTap: () => _selectBirthday(context),
                      decoration: _inputDecoration(
                        'Date of Birth',
                        Icons.cake_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_month, color: maroonColor),
                          onPressed: () => _selectBirthday(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _addressCtrl,
                      decoration: _inputDecoration(
                        'Home / Complete Address',
                        Icons.location_on_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.map, color: maroonColor),
                          tooltip: 'Pick on Map',
                          onPressed: () async {
                            final selected = await LocationPickerDialog.show(
                              context,
                              initialAddress: _addressCtrl.text,
                            );
                            if (selected != null && selected.isNotEmpty) {
                              setState(() {
                                _addressCtrl.text = selected;
                              });
                              setModalState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: maroonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        onPressed: () {
                          _dataService.updateCustomerProfile(
                            name: _nameCtrl.text.trim(),
                            phone: _phoneCtrl.text.trim(),
                            birthday: _birthdayCtrl.text.trim(),
                            address: _addressCtrl.text.trim(),
                          );
                          Navigator.pop(modalContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile information saved successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text(
                          'SAVE PROFILE CHANGES',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
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

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);
    final currentCustomer = _dataService.currentCustomer ??
        CustomerModel(
          id: 'c_guest',
          name: 'Juan Dela Cruz',
          email: 'juan@gmail.com',
          phone: '0917-111-2233',
          birthday: '1996-01-01',
          address: 'Naval, Biliran, Philippines',
        );

    final filteredWorkers = _dataService.getWorkersByCategory(_selectedCategory);

    final hasAvatar = currentCustomer.profileImagePath != null &&
        currentCustomer.profileImagePath!.isNotEmpty;

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
              // Top Left Corner Profile Circle Avatar (Clicking opens Profile Modal)
              GestureDetector(
                onTap: () => _openCustomerProfileModal(context, currentCustomer),
                child: Stack(
                  children: [
                    _buildAvatarImage(currentCustomer.profileImagePath, radius: 22, fallbackInitial: currentCustomer.name),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.black87, size: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openCustomerProfileModal(context, currentCustomer),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${currentCustomer.name.split(' ').first}! 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Tap profile icon to view/edit info',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              tooltip: 'View Profile',
              onPressed: () => _openCustomerProfileModal(context, currentCustomer),
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
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            indicatorWeight: 3,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: [
              Tab(
                icon: Icon(Icons.engineering_outlined),
                text: 'Hire Workers',
              ),
              Tab(
                icon: Icon(Icons.map_outlined),
                text: 'Worker Map',
              ),
              Tab(
                icon: Icon(Icons.assignment_outlined),
                text: 'My Bookings',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Hire Skilled Workers
            _buildWorkersTab(maroonColor, filteredWorkers),

            // TAB 2: Interactive Location Map
            _buildMapTab(maroonColor),

            // TAB 3: Customer Job Bookings Status
            _buildBookingsTab(maroonColor, currentCustomer),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: maroonColor,
          elevation: 4,
          icon: const Icon(Icons.add_task, color: Colors.white),
          label: const Text(
            'Post Job Request',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
          // Banner Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF800000), Color(0xFF5A0000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: maroonColor.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user, color: Colors.amber, size: 40),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Certified Local Service Pros',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Browse verified workers registered on Hanap Gawa.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Explore Service Categories:',
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
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Workers (${workersList.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: maroonColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedCategory,
                  style: TextStyle(color: maroonColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Worker Cards List (Shows empty state when no worker is registered)
          if (workersList.isEmpty)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No registered workers available in this category.',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Newly registered workers will appear here in real-time.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
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
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
        selectedColor: maroonColor,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? maroonColor : Colors.grey.shade300),
        ),
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
      margin: const EdgeInsets.only(bottom: 14),
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: maroonColor,
                      child: Text(
                        worker.name.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified, color: Colors.blue, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.green[800],
                              borderRadius: BorderRadius.circular(8),
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
                      const SizedBox(height: 4),
                      Text(
                        '${worker.workCategory} • ${worker.address}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          Text(
                            ' ${worker.rating} ',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '(${worker.completedJobs} jobs done)',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Credentials & Permit Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'NC Certificate: ${worker.nationalCertificateNo}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.badge, color: maroonColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Working Permit: ${worker.workingPermitNo}',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Book Worker Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
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
                icon: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                label: Text(
                  'Book ${worker.name.split(' ').first} Now (₱${worker.hourlyRate.toStringAsFixed(0)}/hr)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: maroonColor, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Real-Time Job Request Map',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: maroonColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap any pin on the map to inspect rate details (₱/hr) & job descriptions.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Custom Map Widget
          InteractiveMapWidget(
            jobs: _dataService.jobs,
            workers: _dataService.workers,
            height: 460,
          ),
        ],
      ),
    );
  }

  // TAB 3: Customer Job Bookings Status
  Widget _buildBookingsTab(Color maroonColor, CustomerModel customer) {
    final allJobs = _dataService.jobs;

    final jobs = allJobs.where((j) {
      if (_bookingStatusFilter == 'All') return true;
      return j.status.toLowerCase() == _bookingStatusFilter.toLowerCase();
    }).toList();

    return Column(
      children: [
        // Status Filter Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', 'Pending', 'Accepted', 'Completed'].map((status) {
                      final isSelected = _bookingStatusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          selectedColor: maroonColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _bookingStatusFilter = status;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: jobs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 56, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'No $_bookingStatusFilter job requests found.',
                        style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap "Post Job Request" below to request a service!',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final isAccepted = job.status == 'Accepted';
                    final isCompleted = job.status == 'Completed';

                    Color statusColor = Colors.orange.shade800;
                    if (isAccepted) statusColor = Colors.blue.shade800;
                    if (isCompleted) statusColor = Colors.green.shade800;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: maroonColor,
                          child: const Icon(Icons.work, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          job.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          '${job.workCategory} • ₱${job.hourlyRate.toStringAsFixed(0)}/hr',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            job.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        children: [
                          Container(
                            color: Colors.grey[50],
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Work Description:',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: maroonColor, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(job.workDetails, style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: maroonColor),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Location: ${job.customerAddress}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.payments, size: 16, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Estimated Total: ₱${job.estimatedTotal.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ],
                                ),
                                if (job.assignedWorkerName != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person, color: Colors.blue, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Assigned Pro: ${job.assignedWorkerName}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: maroonColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                    label: const Text(
                                      'VIEW FULL JOB DETAILS & MAP',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(String? imagePath, {double radius = 22, String fallbackInitial = 'C'}) {
    const maroonColor = Color(0xFF800000);
    final hasAvatar = imagePath != null && imagePath.isNotEmpty;

    if (hasAvatar) {
      if (kIsWeb || imagePath.startsWith('http') || imagePath.startsWith('blob:') || imagePath.startsWith('assets/')) {
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
        } catch (e) {
          // Fallback
        }
      }
    }

    final isSmall = radius <= 25;

    return CircleAvatar(
      radius: radius,
      backgroundColor: isSmall ? Colors.white : maroonColor,
      child: Text(
        fallbackInitial.isNotEmpty ? fallbackInitial[0].toUpperCase() : 'C',
        style: TextStyle(
          color: isSmall ? maroonColor : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    const maroonColor = Color(0xFF800000);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: maroonColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: maroonColor, width: 2),
      ),
    );
  }
}
