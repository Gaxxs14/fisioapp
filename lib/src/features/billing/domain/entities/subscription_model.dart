class SubscriptionModel {
  final String clinicId;
  final String planName;
  final String status;
  final DateTime trialEndsAt;
  final DateTime currentPeriodEnd;
  final double price;

  const SubscriptionModel({
    required this.clinicId,
    required this.planName,
    required this.status,
    required this.trialEndsAt,
    required this.currentPeriodEnd,
    required this.price,
  });

  SubscriptionModel copyWith({
    String? clinicId,
    String? planName,
    String? status,
    DateTime? trialEndsAt,
    DateTime? currentPeriodEnd,
    double? price,
  }) {
    return SubscriptionModel(
      clinicId: clinicId ?? this.clinicId,
      planName: planName ?? this.planName,
      status: status ?? this.status,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clinicId': clinicId,
      'planName': planName,
      'status': status,
      'trialEndsAt': trialEndsAt.toIso8601String(),
      'currentPeriodEnd': currentPeriodEnd.toIso8601String(),
      'price': price,
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      clinicId: map['clinicId'] ?? '',
      planName: map['planName'] ?? 'Básico',
      status: map['status'] ?? 'trialing',
      trialEndsAt: map['trialEndsAt'] != null ? DateTime.parse(map['trialEndsAt']) : DateTime.now().add(const Duration(days: 14)),
      currentPeriodEnd: map['currentPeriodEnd'] != null ? DateTime.parse(map['currentPeriodEnd']) : DateTime.now().add(const Duration(days: 14)),
      price: (map['price'] as num?)?.toDouble() ?? 29.00,
    );
  }
}
