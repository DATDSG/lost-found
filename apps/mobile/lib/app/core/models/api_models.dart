// Manual JSON serialization implementation

/// Report type enum
enum ReportType {
  /// Lost item report
  lost,

  /// Found item report
  found,
}

/// Report status enum
enum ReportStatus {
  /// Report is pending approval
  pending,

  /// Report has been approved
  approved,

  /// Report is hidden from public view
  hidden,

  /// Report has been removed
  removed,

  /// Report has been rejected
  rejected,
}

/// User model
class User {
  /// Creates a new [User] instance
  User({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.displayName,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    this.location,
    this.gender,
    this.dateOfBirth,
  });

  /// Creates a [User] instance from JSON
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    isActive: json['is_active'] as bool,
    createdAt: DateTime.parse(json['created_at'] as String),
    displayName: json['display_name'] as String?,
    phoneNumber: json['phone_number'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    bio: json['bio'] as String?,
    location: json['location'] as String?,
    gender: json['gender'] as String?,
    dateOfBirth: json['date_of_birth'] != null
        ? DateTime.parse(json['date_of_birth'] as String)
        : null,
  );

  /// Unique identifier for the user
  final String id;

  /// User's email address
  final String email;

  /// User's display name
  final String? displayName;

  /// User's phone number
  final String? phoneNumber;

  /// URL to user's avatar image
  final String? avatarUrl;

  /// User's bio/description
  final String? bio;

  /// User's location
  final String? location;

  /// User's gender
  final String? gender;

  /// User's date of birth
  final DateTime? dateOfBirth;

  /// User's role in the system
  final String role;

  /// Whether the user account is active
  final bool isActive;

  /// When the user account was created
  final DateTime createdAt;

  /// Converts this [User] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'role': role,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'display_name': displayName,
    'phone_number': phoneNumber,
    'avatar_url': avatarUrl,
    'bio': bio,
    'location': location,
    'gender': gender,
    'date_of_birth': dateOfBirth?.toIso8601String(),
  };
}

/// Media model
class Media {
  /// Creates a new [Media] instance
  Media({
    required this.id,
    required this.url,
    required this.type,
    required this.filename,
    this.width,
    this.height,
    this.sizeBytes,
  });

  /// Creates a [Media] instance from JSON
  factory Media.fromJson(Map<String, dynamic> json) => Media(
    id: json['id'] as String,
    url: json['url'] as String,
    type: json['type'] as String,
    filename: json['filename'] as String,
    width: json['width'] as int?,
    height: json['height'] as int?,
    sizeBytes: json['size_bytes'] as int?,
  );

  /// Unique identifier for the media
  final String id;

  /// URL to the media file
  final String url;

  /// Type of media (image, video, etc.)
  final String type;

  /// Original filename of the media
  final String filename;

  /// Width of the media in pixels
  final int? width;

  /// Height of the media in pixels
  final int? height;

  /// Size of the media file in bytes
  final int? sizeBytes;

  /// Converts this [Media] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'type': type,
    'filename': filename,
    'width': width,
    'height': height,
    'size_bytes': sizeBytes,
  };
}

/// Report response model (full report data from API)
class ReportResponse {
  /// Creates a new [ReportResponse] instance
  ReportResponse({
    required this.id,
    required this.title,
    required this.status,
    required this.type,
    required this.category,
    required this.locationCity,
    required this.createdAt,
    required this.updatedAt,
    required this.ownerId,
    this.description,
    this.locationAddress,
    this.occurredAt,
    this.occurredTime,
    this.latitude,
    this.longitude,
    this.contactInfo,
    this.isUrgent = false,
    this.rewardOffered = false,
    this.rewardAmount,
    this.images = const [],
    this.imageHashes = const [],
    this.colors = const [],
  });

  /// Creates a [ReportResponse] instance from JSON
  factory ReportResponse.fromJson(Map<String, dynamic> json) => ReportResponse(
    id: json['id'] as String,
    title: json['title'] as String,
    status: json['status'] as String,
    type: json['type'] as String,
    category: json['category'] as String,
    locationCity: json['location_city'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    ownerId: json['owner_id'] as String,
    description: json['description'] as String?,
    locationAddress: json['location_address'] as String?,
    occurredAt: json['occurred_at'] != null
        ? DateTime.parse(json['occurred_at'] as String)
        : null,
    occurredTime: json['occurred_time'] as String?,
    latitude: json['latitude'] as double?,
    longitude: json['longitude'] as double?,
    contactInfo: json['contact_info'] as String?,
    isUrgent: json['is_urgent'] as bool? ?? false,
    rewardOffered: json['reward_offered'] as bool? ?? false,
    rewardAmount: json['reward_amount'] as String?,
    images: (json['images'] as List<dynamic>?)?.cast<String>() ?? const [],
    imageHashes:
        (json['image_hashes'] as List<dynamic>?)?.cast<String>() ?? const [],
    colors: (json['colors'] as List<dynamic>?)?.cast<String>() ?? const [],
  );

  /// Unique identifier for the report
  final String id;

  /// Title of the report
  final String title;

  /// Description of the item
  final String? description;

  /// Current status of the report
  final String status;

  /// Type of report (lost or found)
  final String type;

  /// Category of the item
  final String category;

  /// Colors of the item
  final List<String> colors;

  /// When the incident occurred
  final DateTime? occurredAt;

  /// Time when the incident occurred
  final String? occurredTime;

  /// City where the item was lost/found
  final String locationCity;

  /// Address where the item was lost/found
  final String? locationAddress;

  /// Latitude coordinate
  final double? latitude;

  /// Longitude coordinate
  final double? longitude;

  /// Contact information
  final String? contactInfo;

  /// Whether this is urgent
  final bool isUrgent;

  /// Whether a reward is offered
  final bool rewardOffered;

  /// Amount of reward offered
  final String? rewardAmount;

  /// Images associated with the report
  final List<String> images;

  /// Image hashes for deduplication
  final List<String> imageHashes;

  /// Owner of the report
  final String ownerId;

  /// When the report was created
  final DateTime createdAt;

  /// When the report was last updated
  final DateTime updatedAt;

  /// Converts this [ReportResponse] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'type': type,
    'category': category,
    'location_city': locationCity,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'owner_id': ownerId,
    'description': description,
    'location_address': locationAddress,
    'occurred_at': occurredAt?.toIso8601String(),
    'occurred_time': occurredTime,
    'latitude': latitude,
    'longitude': longitude,
    'contact_info': contactInfo,
    'is_urgent': isUrgent,
    'reward_offered': rewardOffered,
    'reward_amount': rewardAmount,
    'images': images,
    'image_hashes': imageHashes,
    'colors': colors,
  };
}

/// Report summary model
class ReportSummary {
  /// Creates a new [ReportSummary] instance
  ReportSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.type,
    required this.category,
    required this.city,
    required this.createdAt,
    this.description,
    this.images = const [],
    this.contactInfo,
    this.colors,
  });

  /// Creates a [ReportSummary] instance from JSON
  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
    id: json['id'] as String,
    title: json['title'] as String,
    status: json['status'] as String,
    type: json['type'] as String,
    category: json['category'] as String,
    city: json['location_city'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    description: json['description'] as String?,
    images: (json['images'] as List<dynamic>?)?.cast<String>() ?? const [],
    contactInfo: json['contact_info'] as String?,
    colors: (json['colors'] as List<dynamic>?)?.cast<String>(),
  );

  /// Unique identifier for the report
  final String id;

  /// Title of the report
  final String title;

  /// Description of the item
  final String? description;

  /// Current status of the report
  final String status;

  /// Type of report (lost or found)
  final String type;

  /// Category of the item
  final String category;

  /// Colors of the item
  final List<String>? colors;

  /// City where the item was lost/found
  final String city;

  /// Images associated with the report
  final List<String> images;

  /// Contact information
  final String? contactInfo;

  /// When the report was created
  final DateTime createdAt;

  /// Converts this [ReportSummary] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'type': type,
    'category': category,
    'location_city': city,
    'created_at': createdAt.toIso8601String(),
    'description': description,
    'images': images,
    'contact_info': contactInfo,
    'colors': colors,
  };
}

/// Report detail model
class ReportDetail extends ReportSummary {
  /// Creates a new [ReportDetail] instance
  ReportDetail({
    required super.id,
    required super.title,
    required super.status,
    required super.type,
    required super.category,
    required super.city,
    required super.createdAt,
    required this.occurredAt,
    required this.isResolved,
    super.images,
    super.contactInfo,
    super.colors,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.rewardOffered,
  });

  /// Creates a [ReportDetail] instance from JSON
  factory ReportDetail.fromJson(Map<String, dynamic> json) => ReportDetail(
    id: json['id'] as String,
    title: json['title'] as String,
    status: json['status'] as String,
    type: json['type'] as String,
    category: json['category'] as String,
    city: json['location_city'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    occurredAt: DateTime.parse(json['occurred_at'] as String),
    isResolved: json['is_resolved'] as bool,
    images: (json['images'] as List<dynamic>?)?.cast<String>() ?? const [],
    contactInfo: json['contact_info'] as String?,
    colors: (json['colors'] as List<dynamic>?)?.cast<String>(),
    latitude: json['latitude'] as double?,
    longitude: json['longitude'] as double?,
    locationAddress: json['location_address'] as String?,
    rewardOffered: json['reward_offered'] as bool?,
  );

  /// When the item was lost/found
  final DateTime occurredAt;

  /// Latitude coordinate of the location
  final double? latitude;

  /// Longitude coordinate of the location
  final double? longitude;

  /// Specific address where the item was lost/found
  final String? locationAddress;

  /// Whether a reward is offered for finding the item
  final bool? rewardOffered;

  /// Whether the report has been resolved
  final bool isResolved;

  /// Converts this [ReportDetail] instance to a JSON map
  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'occurred_at': occurredAt.toIso8601String(),
    'is_resolved': isResolved,
    'latitude': latitude,
    'longitude': longitude,
    'location_address': locationAddress,
    'reward_offered': rewardOffered,
  };
}

/// Report creation model
class ReportCreate {
  /// Creates a new [ReportCreate] instance
  ReportCreate({
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.locationCity,
    this.locationAddress,
    this.occurredAt,
    this.occurredTime,
    this.latitude,
    this.longitude,
    this.contactInfo,
    this.isUrgent = false,
    this.rewardOffered = false,
    this.rewardAmount,
    this.colors = const [],
    this.images = const [],
    this.condition,
    this.additionalInfo,
    this.brand,
    this.model,
    this.serialNumber,
    this.size,
    this.material,
    this.estimatedValue,
    this.lastSeenLocation,
    this.circumstancesOfLoss,
    this.safetyStatus,
    this.isSafe,
    this.foundCircumstances,
    this.storageLocation,
    this.handlingInstructions,
    this.hasSerialNumber,
    this.isInsured,
    this.hasReceipt,
    this.isValuable,
    this.needsSpecialHandling,
    this.turnedIntoPolice,
    this.mediaIds = const [],
  });

  /// Creates a [ReportCreate] instance from JSON
  factory ReportCreate.fromJson(Map<String, dynamic> json) => ReportCreate(
    title: json['title'] as String,
    description: json['description'] as String,
    type: json['type'] as String,
    category: json['category'] as String,
    locationCity: json['location_city'] as String,
    locationAddress: json['location_address'] as String?,
    occurredAt: json['occurred_at'] != null
        ? DateTime.parse(json['occurred_at'] as String)
        : null,
    occurredTime: json['occurred_time'] as String?,
    latitude: json['latitude'] as double?,
    longitude: json['longitude'] as double?,
    contactInfo: json['contact_info'] as String?,
    isUrgent: json['is_urgent'] as bool? ?? false,
    rewardOffered: json['reward_offered'] as bool? ?? false,
    rewardAmount: json['reward_amount'] as String?,
    colors: (json['colors'] as List<dynamic>?)?.cast<String>() ?? const [],
    images: (json['images'] as List<dynamic>?)?.cast<String>() ?? const [],
    condition: json['condition'] as String?,
    additionalInfo: json['additional_info'] as String?,
    brand: json['brand'] as String?,
    model: json['model'] as String?,
    serialNumber: json['serial_number'] as String?,
    size: json['size'] as String?,
    material: json['material'] as String?,
    estimatedValue: json['estimated_value'] as String?,
    lastSeenLocation: json['last_seen_location'] as String?,
    circumstancesOfLoss: json['circumstances_of_loss'] as String?,
    safetyStatus: json['safety_status'] as String?,
    isSafe: json['is_safe'] as bool?,
    foundCircumstances: json['found_circumstances'] as String?,
    storageLocation: json['storage_location'] as String?,
    handlingInstructions: json['handling_instructions'] as String?,
    hasSerialNumber: json['has_serial_number'] as bool?,
    isInsured: json['is_insured'] as bool?,
    hasReceipt: json['has_receipt'] as bool?,
    isValuable: json['is_valuable'] as bool?,
    needsSpecialHandling: json['needs_special_handling'] as bool?,
    turnedIntoPolice: json['turned_into_police'] as bool?,
    mediaIds: (json['media_ids'] as List<dynamic>?)?.cast<String>() ?? const [],
  );

  /// Title of the report
  final String title;

  /// Description of the item
  final String description;

  /// Type of report (lost or found)
  final String type;

  /// Category of the item
  final String category;

  /// Colors of the item
  final List<String> colors;

  /// City where the item was lost/found
  final String locationCity;

  /// Address where the item was lost/found
  final String? locationAddress;

  /// When the incident occurred
  final DateTime? occurredAt;

  /// Time when the incident occurred
  final String? occurredTime;

  /// Latitude coordinate
  final double? latitude;

  /// Longitude coordinate
  final double? longitude;

  /// Contact information
  final String? contactInfo;

  /// Whether this is urgent
  final bool isUrgent;

  /// Whether a reward is offered
  final bool rewardOffered;

  /// Amount of reward offered
  final String? rewardAmount;

  /// Images associated with the report
  final List<String> images;

  /// Condition of the item
  final String? condition;

  /// Additional information
  final String? additionalInfo;

  /// Brand of the item
  final String? brand;

  /// Model of the item
  final String? model;

  /// Serial number of the item
  final String? serialNumber;

  /// Size of the item
  final String? size;

  /// Material of the item
  final String? material;

  /// Estimated value of the item
  final String? estimatedValue;

  /// Last seen location (for lost items)
  final String? lastSeenLocation;

  /// Circumstances of loss (for lost items)
  final String? circumstancesOfLoss;

  /// Safety status (for found items)
  final String? safetyStatus;

  /// Whether the item is safe to handle
  final bool? isSafe;

  /// Found circumstances (for found items)
  final String? foundCircumstances;

  /// Storage location (for found items)
  final String? storageLocation;

  /// Handling instructions (for found items)
  final String? handlingInstructions;

  /// Whether the item has a serial number
  final bool? hasSerialNumber;

  /// Whether the item is insured
  final bool? isInsured;

  /// Whether the user has a receipt
  final bool? hasReceipt;

  /// Whether the item is valuable
  final bool? isValuable;

  /// Whether the item needs special handling
  final bool? needsSpecialHandling;

  /// Whether the item was turned into police
  final bool? turnedIntoPolice;

  /// Media IDs associated with the report
  final List<String> mediaIds;

  /// Converts this [ReportCreate] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'type': type,
    'category': category,
    'location_city': locationCity,
    'location_address': locationAddress,
    'occurred_at': occurredAt?.toIso8601String(),
    'occurred_time': occurredTime,
    'latitude': latitude,
    'longitude': longitude,
    'contact_info': contactInfo,
    'is_urgent': isUrgent,
    'reward_offered': rewardOffered,
    'reward_amount': rewardAmount,
    'colors': colors,
    'images': images,
    'condition': condition,
    'additional_info': additionalInfo,
    'brand': brand,
    'model': model,
    'serial_number': serialNumber,
    'size': size,
    'material': material,
    'estimated_value': estimatedValue,
    'last_seen_location': lastSeenLocation,
    'circumstances_of_loss': circumstancesOfLoss,
    'safety_status': safetyStatus,
    'is_safe': isSafe,
    'found_circumstances': foundCircumstances,
    'storage_location': storageLocation,
    'handling_instructions': handlingInstructions,
    'has_serial_number': hasSerialNumber,
    'is_insured': isInsured,
    'has_receipt': hasReceipt,
    'is_valuable': isValuable,
    'needs_special_handling': needsSpecialHandling,
    'turned_into_police': turnedIntoPolice,
    'media_ids': mediaIds,
  };
}

/// Category model
class Category {
  /// Creates a new [Category] instance
  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.isActive,
    required this.createdAt,
  });

  /// Creates a [Category] instance from JSON
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String,
    isActive: json['is_active'] as bool,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  /// Unique identifier for the category
  final String id;

  /// Name of the category
  final String name;

  /// Icon for the category
  final String icon;

  /// Whether the category is active
  final bool isActive;

  /// When the category was created
  final DateTime createdAt;

  /// Converts this [Category] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Color model
class Color {
  /// Creates a new [Color] instance
  Color({
    required this.id,
    required this.name,
    required this.hexCode,
    required this.isActive,
    required this.createdAt,
  });

  /// Creates a [Color] instance from JSON
  factory Color.fromJson(Map<String, dynamic> json) => Color(
    id: json['id'] as String,
    name: json['name'] as String,
    hexCode: json['hex_code'] as String,
    isActive: json['is_active'] as bool,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  /// Unique identifier for the color
  final String id;

  /// Name of the color
  final String name;

  /// Hex code of the color
  final String hexCode;

  /// Whether the color is active
  final bool isActive;

  /// When the color was created
  final DateTime createdAt;

  /// Converts this [Color] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hex_code': hexCode,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Login request model
class LoginRequest {
  /// Creates a new [LoginRequest] instance
  LoginRequest({required this.email, required this.password});

  /// Creates a [LoginRequest] instance from JSON
  factory LoginRequest.fromJson(Map<String, dynamic> json) => LoginRequest(
    email: json['email'] as String,
    password: json['password'] as String,
  );

  /// Email address
  final String email;

  /// Password
  final String password;

  /// Converts this [LoginRequest] instance to a JSON map
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

/// Register request model
class RegisterRequest {
  /// Creates a new [RegisterRequest] instance
  RegisterRequest({
    required this.email,
    required this.password,
    this.displayName,
    this.phoneNumber,
  });

  /// Creates a [RegisterRequest] instance from JSON
  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      RegisterRequest(
        email: json['email'] as String,
        password: json['password'] as String,
        displayName: json['display_name'] as String?,
        phoneNumber: json['phone_number'] as String?,
      );

  /// Email address
  final String email;

  /// Password
  final String password;

  /// Display name
  final String? displayName;

  /// Phone number
  final String? phoneNumber;

  /// Converts this [RegisterRequest] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'display_name': displayName,
    'phone_number': phoneNumber,
  };
}

/// Forgot password request model
class ForgotPasswordRequest {
  /// Creates a new [ForgotPasswordRequest] instance
  ForgotPasswordRequest({required this.email});

  /// Creates a [ForgotPasswordRequest] instance from JSON
  factory ForgotPasswordRequest.fromJson(Map<String, dynamic> json) =>
      ForgotPasswordRequest(email: json['email'] as String);

  /// Email address
  final String email;

  /// Converts this [ForgotPasswordRequest] instance to a JSON map
  Map<String, dynamic> toJson() => {'email': email};
}

/// Reset password request model
class ResetPasswordRequest {
  /// Creates a new [ResetPasswordRequest] instance
  ResetPasswordRequest({required this.token, required this.newPassword});

  /// Creates a [ResetPasswordRequest] instance from JSON
  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      ResetPasswordRequest(
        token: json['token'] as String,
        newPassword: json['new_password'] as String,
      );

  /// Reset token
  final String token;

  /// New password
  final String newPassword;

  /// Converts this [ResetPasswordRequest] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'token': token,
    'new_password': newPassword,
  };
}

/// Authentication response model
class AuthResponse {
  /// Creates a new [AuthResponse] instance
  AuthResponse({required this.accessToken, required this.tokenType, this.user});

  /// Creates an [AuthResponse] instance from JSON
  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: json['access_token'] as String,
    tokenType: json['token_type'] as String,
    user: json['user'] != null
        ? User.fromJson(json['user'] as Map<String, dynamic>)
        : null,
  );

  /// User information (optional, not always present in login response)
  final User? user;

  /// Access token
  final String accessToken;

  /// Token type
  final String tokenType;

  /// Converts this [AuthResponse] instance to a JSON map
  Map<String, dynamic> toJson() => {
    if (user != null) 'user': user!.toJson(),
    'access_token': accessToken,
    'token_type': tokenType,
  };
}

/// Match summary model
class MatchSummary {
  /// Creates a new [MatchSummary] instance
  MatchSummary({
    required this.id,
    required this.sourceReportId,
    required this.candidateReportId,
    required this.status,
    required this.scoreTotal,
    required this.createdAt,
    this.scoreText,
    this.scoreImage,
    this.scoreGeo,
    this.scoreTime,
    this.scoreColor,
  });

  /// Creates a [MatchSummary] instance from JSON
  factory MatchSummary.fromJson(Map<String, dynamic> json) => MatchSummary(
    id: json['id'] as String,
    sourceReportId: json['source_report_id'] as String,
    candidateReportId: json['candidate_report_id'] as String,
    status: json['status'] as String,
    scoreTotal: json['score_total'] as double,
    createdAt: DateTime.parse(json['created_at'] as String),
    scoreText: json['score_text'] as double?,
    scoreImage: json['score_image'] as double?,
    scoreGeo: json['score_geo'] as double?,
    scoreTime: json['score_time'] as double?,
    scoreColor: json['score_color'] as double?,
  );

  /// Unique identifier for the match
  final String id;

  /// ID of the source report
  final String sourceReportId;

  /// ID of the candidate report
  final String candidateReportId;

  /// Current status of the match
  final String status;

  /// Total match score
  final double scoreTotal;

  /// Text similarity score
  final double? scoreText;

  /// Image similarity score
  final double? scoreImage;

  /// Geographic proximity score
  final double? scoreGeo;

  /// Time proximity score
  final double? scoreTime;

  /// Color similarity score
  final double? scoreColor;

  /// When the match was created
  final DateTime createdAt;

  /// Converts this [MatchSummary] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'source_report_id': sourceReportId,
    'candidate_report_id': candidateReportId,
    'status': status,
    'score_total': scoreTotal,
    'created_at': createdAt.toIso8601String(),
    'score_text': scoreText,
    'score_image': scoreImage,
    'score_geo': scoreGeo,
    'score_time': scoreTime,
    'score_color': scoreColor,
  };
}

/// Pagination model
class PaginatedResponse<T> {
  /// Creates a new [PaginatedResponse] instance
  PaginatedResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  /// Creates a [PaginatedResponse] instance from JSON
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) => PaginatedResponse(
    data: (json['data'] as List<dynamic>)
        .map((item) => fromJsonT(item as Map<String, dynamic>))
        .toList(),
    total: json['total'] as int,
    page: json['page'] as int,
    perPage: json['per_page'] as int,
    totalPages: json['total_pages'] as int,
  );

  /// List of items
  final List<T> data;

  /// Total number of items
  final int total;

  /// Current page number
  final int page;

  /// Number of items per page
  final int perPage;

  /// Total number of pages
  final int totalPages;

  /// Converts this [PaginatedResponse] instance to a JSON map
  Map<String, dynamic> toJson(Object Function(T) toJsonT) => {
    'data': data.map(toJsonT).toList(),
    'total': total,
    'page': page,
    'per_page': perPage,
    'total_pages': totalPages,
  };
}
