enum UserRole { customer, worker }

class WorkCategory {
  final String id;
  final String title;
  final String iconName;
  final String description;

  const WorkCategory({
    required this.id,
    required this.title,
    required this.iconName,
    required this.description,
  });

  static const List<WorkCategory> categories = [
    WorkCategory(
      id: 'carpentry',
      title: 'Carpentry',
      iconName: 'carpentry',
      description: 'Furniture repair, roofing, woodwork, door & window installations',
    ),
    WorkCategory(
      id: 'plumbing',
      title: 'Water Repairman / Plumbing',
      iconName: 'plumbing',
      description: 'Pipe leaks, water heater repair, toilet & sink installation',
    ),
    WorkCategory(
      id: 'electrical',
      title: 'Electrical',
      iconName: 'electrical',
      description: 'Wiring, circuit breaker, lighting, socket installation',
    ),
    WorkCategory(
      id: 'appliance',
      title: 'Appliance Repair',
      iconName: 'appliance',
      description: 'Aircon cleaning/repair, refrigerator, washing machine fix',
    ),
    WorkCategory(
      id: 'painting',
      title: 'Painting & Finishing',
      iconName: 'painting',
      description: 'Interior & exterior house painting, wall varnishing',
    ),
    WorkCategory(
      id: 'masonry',
      title: 'Masonry & Tiling',
      iconName: 'masonry',
      description: 'Concrete work, wall plastering, floor tile laying',
    ),
    WorkCategory(
      id: 'cleaning',
      title: 'House Cleaning',
      iconName: 'cleaning',
      description: 'Deep house cleaning, post-construction cleanup',
    ),
    WorkCategory(
      id: 'gardening',
      title: 'Gardening & Landscaping',
      iconName: 'gardening',
      description: 'Lawn mowing, tree trimming, garden maintenance',
    ),
  ];
}

class CustomerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String birthday;
  final String address;
  final double latitude;
  final double longitude;
  final String? profileImagePath;

  CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.birthday,
    required this.address,
    this.latitude = 11.5606,
    this.longitude = 124.3986,
    this.profileImagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'birthday': birthday,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'profile_image_path': profileImagePath,
      };

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        birthday: json['birthday'] ?? '',
        address: json['address'] ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 11.5606,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 124.3986,
        profileImagePath: json['profile_image_path'],
      );

  CustomerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? birthday,
    String? address,
    double? latitude,
    double? longitude,
    String? profileImagePath,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}

class WorkerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String workCategory; // e.g. Carpentry, Plumbing
  final double hourlyRate;   // Money rate per hour in PHP
  final String workingPermitNo;
  final String nationalCertificateNo; // TESDA / NC II certificate
  final String proficiencyProof;      // Document name / info
  final double rating;
  final int completedJobs;
  final bool isAvailable;
  final double latitude;
  final double longitude;

  WorkerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.workCategory,
    required this.hourlyRate,
    required this.workingPermitNo,
    required this.nationalCertificateNo,
    required this.proficiencyProof,
    this.rating = 4.8,
    this.completedJobs = 12,
    this.isAvailable = true,
    this.latitude = 11.5610,
    this.longitude = 124.3990,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'work_category': workCategory,
        'hourly_rate': hourlyRate,
        'working_permit_no': workingPermitNo,
        'national_certificate_no': nationalCertificateNo,
        'proficiency_proof': proficiencyProof,
        'rating': rating,
        'completed_jobs': completedJobs,
        'is_available': isAvailable,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory WorkerModel.fromJson(Map<String, dynamic> json) => WorkerModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        address: json['address'] ?? '',
        workCategory: json['work_category'] ?? 'Carpentry',
        hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 250.0,
        workingPermitNo: json['working_permit_no'] ?? '',
        nationalCertificateNo: json['national_certificate_no'] ?? '',
        proficiencyProof: json['proficiency_proof'] ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        completedJobs: (json['completed_jobs'] as num?)?.toInt() ?? 0,
        isAvailable: json['is_available'] ?? true,
        latitude: (json['latitude'] as num?)?.toDouble() ?? 11.5610,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 124.3990,
      );
}

class JobBooking {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double customerLat;
  final double customerLng;
  final String workCategory;
  final String title;
  final String workDetails;
  final double hourlyRate; // Rate per hour offered or requested
  final double estimatedHours;
  final String status; // 'Pending', 'Accepted', 'In Progress', 'Completed', 'Cancelled'
  final String? assignedWorkerId;
  final String? assignedWorkerName;
  final String createdAt;

  JobBooking({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.customerLat,
    required this.customerLng,
    required this.workCategory,
    required this.title,
    required this.workDetails,
    required this.hourlyRate,
    required this.estimatedHours,
    this.status = 'Pending',
    this.assignedWorkerId,
    this.assignedWorkerName,
    required this.createdAt,
  });

  double get estimatedTotal => hourlyRate * estimatedHours;

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_address': customerAddress,
        'customer_lat': customerLat,
        'customer_lng': customerLng,
        'work_category': workCategory,
        'title': title,
        'work_details': workDetails,
        'hourly_rate': hourlyRate,
        'estimated_hours': estimatedHours,
        'status': status,
        'assigned_worker_id': assignedWorkerId,
        'assigned_worker_name': assignedWorkerName,
        'created_at': createdAt,
      };

  factory JobBooking.fromJson(Map<String, dynamic> json) => JobBooking(
        id: json['id'] ?? '',
        customerId: json['customer_id'] ?? '',
        customerName: json['customer_name'] ?? 'Customer',
        customerPhone: json['customer_phone'] ?? '',
        customerAddress: json['customer_address'] ?? '',
        customerLat: (json['customer_lat'] as num?)?.toDouble() ?? 11.5606,
        customerLng: (json['customer_lng'] as num?)?.toDouble() ?? 124.3986,
        workCategory: json['work_category'] ?? 'General Repair',
        title: json['title'] ?? 'Job Request',
        workDetails: json['work_details'] ?? '',
        hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 250.0,
        estimatedHours: (json['estimated_hours'] as num?)?.toDouble() ?? 2.0,
        status: json['status'] ?? 'Pending',
        assignedWorkerId: json['assigned_worker_id'],
        assignedWorkerName: json['assigned_worker_name'],
        createdAt: json['created_at'] ?? '',
      );
}
