

class Store {
  final String id;
  final String ownerId;
  String? ownerName; // <-- ADDED
  String storeName;
  String? storeDescription; // From UI
  String address;
  String pincode;
  String? phone; // From UI
  String? email; // From UI (likely owner's email)
  String? gstNumber; // From UI
  String? storeLogoUrl; // From UI
  bool isOpen;
  bool autoAcceptOrders; // From UI
  int avgPreparationTime; // From UI
  double minOrderValue; // From UI
  final List<double> coordinates; // [lng, lat]
  final WeeklySchedule schedule; // From UI

  Store({
    required this.id,
    required this.ownerId,
    this.ownerName, // <-- ADDED
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
  }) : coordinates = coordinates ?? [0, 0],
       schedule = schedule ?? WeeklySchedule.fromJson({});

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
      // <-- ADDED
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
    );
  }

  // Method to create a map for updates, only including non-null values
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
      sunday: DaySchedule.fromJson(
        json['sunday'] ?? {'isOpen': false},
      ), // Closed by default
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
  String openTime; // "HH:mm" format
  String closeTime; // "HH:mm" format

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
