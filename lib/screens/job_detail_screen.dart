import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../widgets/interactive_map_widget.dart';

class JobDetailScreen extends StatefulWidget {
  final JobBooking job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final DataService _dataService = DataService();

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);
    final job = widget.job;

    final isWorker = _dataService.currentUserRole == UserRole.worker;
    final currentWorker = _dataService.currentWorker;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Location & Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map showing Customer location & rate badge
            Text(
              'Customer Location Map Pin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: maroonColor,
              ),
            ),
            const SizedBox(height: 8),

            InteractiveMapWidget(
              jobs: [job],
              workers: _dataService.workers,
              selectedJob: job,
              height: 280,
            ),
            const SizedBox(height: 16),

            // Job Title & Category
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: Text(
                            job.workCategory,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: maroonColor,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₱${job.hourlyRate.toStringAsFixed(0)} / hr',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Posted on: ${job.createdAt}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const Divider(height: 24),

                    // Work details description
                    const Text(
                      'WORK DETAILS & DESCRIPTION:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: maroonColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        job.workDetails,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Customer Information
                    const Text(
                      'CUSTOMER INFORMATION:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: maroonColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(Icons.person, 'Customer Name', job.customerName),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.phone, 'Contact Number', job.customerPhone),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.location_on, 'Job Address', job.customerAddress),
                    const Divider(height: 24),

                    // Payout Calculation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimated Duration:',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              '${job.estimatedHours} hours',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Estimated Total Payout:',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              '₱${job.estimatedTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: maroonColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    if (isWorker && currentWorker != null) ...[
                      if (job.status == 'Pending')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[800],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              _dataService.acceptJob(job.id, currentWorker);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Job accepted! Customer will be notified.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              setState(() {});
                            },
                            icon: const Icon(Icons.check_circle, color: Colors.white),
                            label: const Text(
                              'ACCEPT THIS JOB REQUEST',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else if (job.status == 'Accepted')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: maroonColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              _dataService.completeJob(job.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Job marked as Completed!'),
                                  backgroundColor: maroonColor,
                                ),
                              );
                              setState(() {});
                            },
                            icon: const Icon(Icons.task_alt, color: Colors.white),
                            label: const Text(
                              'MARK JOB AS COMPLETED',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    const maroonColor = Color(0xFF800000);
    return Row(
      children: [
        Icon(icon, color: maroonColor, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
