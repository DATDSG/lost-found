import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String name;
  final String handle;
  final DateTime memberSince;
  final int itemsPosted;
  final String? avatarPath; // local file path
  final String phone;

  const UserProfile({
    required this.name,
    required this.handle,
    required this.memberSince,
    required this.itemsPosted,
    required this.phone,
    this.avatarPath,
  });

  UserProfile copyWith({
    String? name,
    String? handle,
    DateTime? memberSince,
    int? itemsPosted,
    String? avatarPath,
    String? phone,
  }) {
    return UserProfile(
      name: name ?? this.name,
      handle: handle ?? this.handle,
      memberSince: memberSince ?? this.memberSince,
      itemsPosted: itemsPosted ?? this.itemsPosted,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}

class ProfileService {
  ProfileService._();
  static final ProfileService I = ProfileService._();

  static const _kName = 'profile_name';
  static const _kPhone = 'profile_phone';
  static const _kAvatar = 'profile_avatar';
  static const _kItemsPosted = 'profile_items';
  static const _kMemberSince = 'profile_since';
  static const _kHandle = 'profile_handle';

  final _controller = StreamController<UserProfile>.broadcast();
  Stream<UserProfile> get stream => _controller.stream;

  late SharedPreferences _prefs;
  UserProfile? _profile; // <- nullable until init completes
  bool _ready = false;
  bool get isReady => _ready;

  /// Returns the current profile or throws if not initialized.
  UserProfile get profile {
    final p = _profile;
    if (p == null) {
      throw StateError('ProfileService not initialized. Call init() first.');
    }
    return p;
  }

  Future<void> init() async {
    if (_ready) return; // idempotent
    _prefs = await SharedPreferences.getInstance();

    final name = _prefs.getString(_kName) ?? 'Aruni Perera';
    final phone = _prefs.getString(_kPhone) ?? '0774589348';
    final avatar = _prefs.getString(_kAvatar);
    final items = _prefs.getInt(_kItemsPosted) ?? 3;
    final handle = _prefs.getString(_kHandle) ?? '@arunp';
    final sinceMs = _prefs.getInt(_kMemberSince) ??
        DateTime(2024, 1, 10).millisecondsSinceEpoch;

    _profile = UserProfile(
      name: name,
      handle: handle,
      memberSince: DateTime.fromMillisecondsSinceEpoch(sinceMs),
      itemsPosted: items,
      phone: phone,
      avatarPath: avatar,
    );
    _ready = true;
    _controller.add(_profile!);
  }

  Future<void> update({
    String? name,
    String? phone,
    String? avatarPath,
    int? itemsPosted,
  }) async {
    final p = profile; // safe (throws if not ready)

    if (name != null) await _prefs.setString(_kName, name);
    if (phone != null) await _prefs.setString(_kPhone, phone);
    if (avatarPath != null) await _prefs.setString(_kAvatar, avatarPath);
    if (itemsPosted != null) await _prefs.setInt(_kItemsPosted, itemsPosted);

    _profile = p.copyWith(
      name: name,
      phone: phone,
      avatarPath: avatarPath,
      itemsPosted: itemsPosted,
    );
    _controller.add(_profile!);
  }

  Future<void> setMemberSince(DateTime d) async {
    await _prefs.setInt(_kMemberSince, d.millisecondsSinceEpoch);
    _profile = profile.copyWith(memberSince: d);
    _controller.add(_profile!);
  }
}
