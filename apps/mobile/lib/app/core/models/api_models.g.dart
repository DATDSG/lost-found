// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  role: json['role'] as String,
  isActive: json['is_active'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  displayName: json['display_name'] as String?,
  phoneNumber: json['phone_number'] as String?,
  avatarUrl: json['avatar_url'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'display_name': instance.displayName,
  'phone_number': instance.phoneNumber,
  'avatar_url': instance.avatarUrl,
  'role': instance.role,
  'is_active': instance.isActive,
  'created_at': instance.createdAt.toIso8601String(),
};

Media _$MediaFromJson(Map<String, dynamic> json) => Media(
  id: json['id'] as String,
  url: json['url'] as String,
  type: json['media_type'] as String,
  filename: json['filename'] as String,
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
  sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
);

Map<String, dynamic> _$MediaToJson(Media instance) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'media_type': instance.type,
  'filename': instance.filename,
  'width': instance.width,
  'height': instance.height,
  'sizeBytes': instance.sizeBytes,
};

ReportSummary _$ReportSummaryFromJson(Map<String, dynamic> json) =>
    ReportSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      status: $enumDecode(_$ReportStatusEnumMap, json['status']),
      type: $enumDecode(_$ReportTypeEnumMap, json['type']),
      category: json['category'] as String,
      city: json['location_city'] as String,
      media: (json['media'] as List<dynamic>)
          .map((e) => Media.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ReportSummaryToJson(ReportSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'status': _$ReportStatusEnumMap[instance.status]!,
      'type': _$ReportTypeEnumMap[instance.type]!,
      'category': instance.category,
      'location_city': instance.city,
      'media': instance.media,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$ReportStatusEnumMap = {
  ReportStatus.pending: 'pending',
  ReportStatus.approved: 'approved',
  ReportStatus.hidden: 'hidden',
  ReportStatus.removed: 'removed',
  ReportStatus.rejected: 'rejected',
};

const _$ReportTypeEnumMap = {
  ReportType.lost: 'lost',
  ReportType.found: 'found',
};

ReportDetail _$ReportDetailFromJson(Map<String, dynamic> json) => ReportDetail(
  id: json['id'] as String,
  title: json['title'] as String,
  status: $enumDecode(_$ReportStatusEnumMap, json['status']),
  type: $enumDecode(_$ReportTypeEnumMap, json['type']),
  category: json['category'] as String,
  city: json['location_city'] as String,
  media: (json['media'] as List<dynamic>)
      .map((e) => Media.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  description: json['description'] as String,
  occurredAt: DateTime.parse(json['occurredAt'] as String),
  isResolved: json['isResolved'] as bool,
  colors: (json['colors'] as List<dynamic>?)?.map((e) => e as String).toList(),
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  locationAddress: json['locationAddress'] as String?,
  rewardOffered: json['rewardOffered'] as bool?,
);

Map<String, dynamic> _$ReportDetailToJson(ReportDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'status': _$ReportStatusEnumMap[instance.status]!,
      'type': _$ReportTypeEnumMap[instance.type]!,
      'category': instance.category,
      'location_city': instance.city,
      'media': instance.media,
      'createdAt': instance.createdAt.toIso8601String(),
      'description': instance.description,
      'colors': instance.colors,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'locationAddress': instance.locationAddress,
      'rewardOffered': instance.rewardOffered,
      'isResolved': instance.isResolved,
    };

ReportCreate _$ReportCreateFromJson(Map<String, dynamic> json) => ReportCreate(
  type: $enumDecode(_$ReportTypeEnumMap, json['type']),
  title: json['title'] as String,
  description: json['description'] as String,
  category: json['category'] as String,
  occurredAt: DateTime.parse(json['occurredAt'] as String),
  colors:
      (json['colors'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  locationCity: json['locationCity'] as String?,
  locationAddress: json['locationAddress'] as String?,
  contactInfo: json['contactInfo'] as String?,
  additionalInfo: json['additionalInfo'] as String?,
  condition: json['condition'] as String?,
  safetyStatus: json['safetyStatus'] as String?,
  isSafe: json['isSafe'] as bool?,
  isUrgent: json['isUrgent'] as bool?,
  rewardOffered: json['rewardOffered'] as bool?,
  rewardAmount: json['rewardAmount'] as String?,
  occurredTime: json['occurredTime'] as String?,
  brand: json['brand'] as String?,
  model: json['model'] as String?,
  serialNumber: json['serialNumber'] as String?,
  size: json['size'] as String?,
  material: json['material'] as String?,
  estimatedValue: json['estimatedValue'] as String?,
  lastSeenLocation: json['lastSeenLocation'] as String?,
  circumstancesOfLoss: json['circumstancesOfLoss'] as String?,
  foundCircumstances: json['foundCircumstances'] as String?,
  storageLocation: json['storageLocation'] as String?,
  handlingInstructions: json['handlingInstructions'] as String?,
  hasSerialNumber: json['hasSerialNumber'] as bool?,
  isInsured: json['isInsured'] as bool?,
  hasReceipt: json['hasReceipt'] as bool?,
  isValuable: json['isValuable'] as bool?,
  needsSpecialHandling: json['needsSpecialHandling'] as bool?,
  turnedIntoPolice: json['turnedIntoPolice'] as bool?,
  mediaIds:
      (json['mediaIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ReportCreateToJson(ReportCreate instance) =>
    <String, dynamic>{
      'type': _$ReportTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'colors': instance.colors,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'occurredTime': instance.occurredTime,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'locationCity': instance.locationCity,
      'locationAddress': instance.locationAddress,
      'contactInfo': instance.contactInfo,
      'additionalInfo': instance.additionalInfo,
      'condition': instance.condition,
      'safetyStatus': instance.safetyStatus,
      'isSafe': instance.isSafe,
      'isUrgent': instance.isUrgent,
      'rewardOffered': instance.rewardOffered,
      'rewardAmount': instance.rewardAmount,
      'brand': instance.brand,
      'model': instance.model,
      'serialNumber': instance.serialNumber,
      'size': instance.size,
      'material': instance.material,
      'estimatedValue': instance.estimatedValue,
      'lastSeenLocation': instance.lastSeenLocation,
      'circumstancesOfLoss': instance.circumstancesOfLoss,
      'foundCircumstances': instance.foundCircumstances,
      'storageLocation': instance.storageLocation,
      'handlingInstructions': instance.handlingInstructions,
      'hasSerialNumber': instance.hasSerialNumber,
      'isInsured': instance.isInsured,
      'hasReceipt': instance.hasReceipt,
      'isValuable': instance.isValuable,
      'needsSpecialHandling': instance.needsSpecialHandling,
      'turnedIntoPolice': instance.turnedIntoPolice,
      'mediaIds': instance.mediaIds,
    };

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: json['id'] as String,
  name: json['name'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  isActive: json['isActive'] as bool,
  icon: json['icon'] as String?,
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'icon': instance.icon,
  'sortOrder': instance.sortOrder,
  'isActive': instance.isActive,
};

Color _$ColorFromJson(Map<String, dynamic> json) => Color(
  id: json['id'] as String,
  name: json['name'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  isActive: json['isActive'] as bool,
  hexCode: json['hexCode'] as String?,
);

Map<String, dynamic> _$ColorToJson(Color instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'hexCode': instance.hexCode,
  'sortOrder': instance.sortOrder,
  'isActive': instance.isActive,
};

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      displayName: json['displayName'] as String?,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'displayName': instance.displayName,
    };

ForgotPasswordRequest _$ForgotPasswordRequestFromJson(
  Map<String, dynamic> json,
) => ForgotPasswordRequest(email: json['email'] as String);

Map<String, dynamic> _$ForgotPasswordRequestToJson(
  ForgotPasswordRequest instance,
) => <String, dynamic>{'email': instance.email};

ResetPasswordRequest _$ResetPasswordRequestFromJson(
  Map<String, dynamic> json,
) => ResetPasswordRequest(
  token: json['token'] as String,
  newPassword: json['new_password'] as String,
);

Map<String, dynamic> _$ResetPasswordRequestToJson(
  ResetPasswordRequest instance,
) => <String, dynamic>{
  'token': instance.token,
  'new_password': instance.newPassword,
};

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  tokenType: json['token_type'] as String? ?? 'bearer',
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'token_type': instance.tokenType,
    };

MatchSummary _$MatchSummaryFromJson(Map<String, dynamic> json) => MatchSummary(
  id: json['id'] as String,
  sourceReportId: json['sourceReportId'] as String,
  candidateReportId: json['candidateReportId'] as String,
  status: json['status'] as String,
  scoreTotal: (json['scoreTotal'] as num).toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  scoreText: (json['scoreText'] as num?)?.toDouble(),
  scoreImage: (json['scoreImage'] as num?)?.toDouble(),
  scoreGeo: (json['scoreGeo'] as num?)?.toDouble(),
  scoreTime: (json['scoreTime'] as num?)?.toDouble(),
  scoreColor: (json['scoreColor'] as num?)?.toDouble(),
);

Map<String, dynamic> _$MatchSummaryToJson(MatchSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sourceReportId': instance.sourceReportId,
      'candidateReportId': instance.candidateReportId,
      'status': instance.status,
      'scoreTotal': instance.scoreTotal,
      'scoreText': instance.scoreText,
      'scoreImage': instance.scoreImage,
      'scoreGeo': instance.scoreGeo,
      'scoreTime': instance.scoreTime,
      'scoreColor': instance.scoreColor,
      'createdAt': instance.createdAt.toIso8601String(),
    };

PaginatedResponse<T> _$PaginatedResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => PaginatedResponse<T>(
  items: (json['items'] as List<dynamic>).map(fromJsonT).toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  pageSize: (json['pageSize'] as num).toInt(),
  hasNext: json['hasNext'] as bool,
);

Map<String, dynamic> _$PaginatedResponseToJson<T>(
  PaginatedResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'items': instance.items.map(toJsonT).toList(),
  'total': instance.total,
  'page': instance.page,
  'pageSize': instance.pageSize,
  'hasNext': instance.hasNext,
};
