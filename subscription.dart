class Subscription {
  final String id;
  String name;
  double price;
  String billingCycle; // 'Monthly' or 'Yearly'
  DateTime renewalDate;

  Subscription({
    required this.id,
    required this.name,
    required this.price,
    required this.billingCycle,
    required this.renewalDate,
  });

  /// Normalizes price to a monthly figure so totals are comparable
  /// regardless of each subscription's billing cycle.
  double get monthlyEquivalent =>
      billingCycle == 'Yearly' ? price / 12 : price;

  int get daysUntilRenewal =>
      renewalDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'billingCycle': billingCycle,
        'renewalDate': renewalDate.toIso8601String(),
      };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        billingCycle: json['billingCycle'] as String,
        renewalDate: DateTime.parse(json['renewalDate'] as String),
      );
}
