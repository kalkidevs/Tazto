class Store {
  final String id;
  final String ownerId;
  String? ownerName;
  String storeName;
  String? storeDescription;
  String address;
  String pincode;
  String? phone;
  String? email;
  String? gstNumber;
  String? storeLogoUrl;
  bool isOpen;
  bool autoAcceptOrders;
  int avgPreparationTime;
  double minOrderValue;
  final List<double> coordinates; // [lng, lat]
  final WeeklySchedule schedule;
  final NotificationPreferences notificationPreferences; // <-- ADDED

  Store({
    required this.id,
    required this.ownerId,
    this.ownerName,
    required this.storeName,
    this.storeDescription,
    required this.address,
    required this.pincode,
    this.phone,
    this.email,
    this.gstNumber,
    this.storeLogoUrl,
    required this.isOpen,
    this.autoAcceptOrders = false,
    this.avgPreparationTime = 15,
    this.minOrderValue = 0,
    List<double>? coordinates,
    WeeklySchedule? schedule,
    NotificationPreferences? notificationPreferences, // <-- ADDED
  }) : coordinates = coordinates ?? [0, 0],
       schedule = schedule ?? WeeklySchedule.fromJson({}),
       notificationPreferences =
           notificationPreferences ?? NotificationPreferences.defaults();

  factory Store.fromJson(Map<String, dynamic> json) {
    // Extract location coordinates
    List<double> coords = [0, 0];
    if (json['location'] != null && json['location']['coordinates'] is List) {
      final coordList = json['location']['coordinates'] as List;
      if (coordList.length == 2) {
        coords = [
          (coordList[0] as num).toDouble(), // lng
          (coordList[1] as num).toDouble(), // lat
        ];
      }
    }

    return Store(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      ownerName: json['ownerName'] as String?,
      storeName: json['storeName'] as String? ?? 'N/A',
      storeDescription: json['storeDescription'] as String?,
      address: json['address'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      gstNumber: json['gstNumber'] as String?,
      storeLogoUrl: json['storeLogoUrl'] as String?,
      isOpen: json['isOpen'] as bool? ?? true,
      autoAcceptOrders: json['autoAcceptOrders'] as bool? ?? false,
      avgPreparationTime: (json['avgPreparationTime'] as num?)?.toInt() ?? 15,
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble() ?? 0,
      coordinates: coords,
      schedule: json['schedule'] != null
          ? WeeklySchedule.fromJson(json['schedule'] as Map<String, dynamic>)
          : WeeklySchedule.fromJson({}),
      notificationPreferences: json['notificationPreferences'] != null
          ? NotificationPreferences.fromJson(
              json['notificationPreferences'] as Map<String, dynamic>,
            )
          : NotificationPreferences.defaults(),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'storeName': storeName,
      'storeDescription': storeDescription,
      'address': address,
      'pincode': pincode,
      'phone': phone,
      'email': email,
      'gstNumber': gstNumber,
      'storeLogoUrl': storeLogoUrl,
      'isOpen': isOpen,
      'autoAcceptOrders': autoAcceptOrders,
      'avgPreparationTime': avgPreparationTime,
      'minOrderValue': minOrderValue,
      'schedule': schedule.toJson(),
      'notificationPreferences': notificationPreferences.toJson(), // <-- ADDED
    };
  }
}

// --- NEW CLASS ---
class NotificationPreferences {
  final bool email;
  final bool sms;
  final bool newOrders;
  final bool lowStock;
  final bool payments;

  NotificationPreferences({
    this.email = true,
    this.sms = false,
    this.newOrders = true,
    this.lowStock = true,
    this.payments = true,
  });

  factory NotificationPreferences.defaults() {
    return NotificationPreferences();
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      email: json['email'] as bool? ?? true,
      sms: json['sms'] as bool? ?? false,
      newOrders: json['newOrders'] as bool? ?? true,
      lowStock: json['lowStock'] as bool? ?? true,
      payments: json['payments'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'sms': sms,
      'newOrders': newOrders,
      'lowStock': lowStock,
      'payments': payments,
    };
  }
}

class WeeklySchedule {
  DaySchedule monday;
  DaySchedule tuesday;
  DaySchedule wednesday;
  DaySchedule thursday;
  DaySchedule friday;
  DaySchedule saturday;
  DaySchedule sunday;

  WeeklySchedule({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    return WeeklySchedule(
      monday: DaySchedule.fromJson(json['monday'] ?? {}),
      tuesday: DaySchedule.fromJson(json['tuesday'] ?? {}),
      wednesday: DaySchedule.fromJson(json['wednesday'] ?? {}),
      thursday: DaySchedule.fromJson(json['thursday'] ?? {}),
      friday: DaySchedule.fromJson(json['friday'] ?? {}),
      saturday: DaySchedule.fromJson(json['saturday'] ?? {}),
      sunday: DaySchedule.fromJson(json['sunday'] ?? {'isOpen': false}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monday': monday.toJson(),
      'tuesday': tuesday.toJson(),
      'wednesday': wednesday.toJson(),
      'thursday': thursday.toJson(),
      'friday': friday.toJson(),
      'saturday': saturday.toJson(),
      'sunday': sunday.toJson(),
    };
  }
}

class DaySchedule {
  bool isOpen;
  String openTime;
  String closeTime;

  DaySchedule({
    this.isOpen = true,
    this.openTime = '08:00',
    this.closeTime = '22:00',
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      isOpen: json['isOpen'] as bool? ?? true,
      openTime: json['openTime'] as String? ?? '08:00',
      closeTime: json['closeTime'] as String? ?? '22:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {'isOpen': isOpen, 'openTime': openTime, 'closeTime': closeTime};
  }
}
