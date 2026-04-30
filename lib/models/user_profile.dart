class UserProfile {
  final String displayName;
  final String email;

  /// Shown before amounts everywhere (e.g. `TZS`, `$`). Stored without trailing space.
  final String currencySymbol;

  /// When true, deadlines and clocks use 24-hour format.
  final bool use24HourTime;

  const UserProfile({
    this.displayName = '',
    this.email = '',
    this.currencySymbol = 'TZS',
    this.use24HourTime = false,
  });

  static const UserProfile empty = UserProfile();

  /// Symbol passed to [NumberFormat.currency] including trailing space.
  String get effectiveCurrencySymbol {
    final c = currencySymbol.trim();
    if (c.isEmpty) return 'TZS ';
    return c.endsWith(' ') ? c : '$c ';
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? currencySymbol,
    bool? use24HourTime,
  }) =>
      UserProfile(
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        use24HourTime: use24HourTime ?? this.use24HourTime,
      );

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'email': email,
        'currencySymbol': currencySymbol,
        'use24HourTime': use24HourTime,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        displayName: json['displayName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        currencySymbol: json['currencySymbol'] as String? ?? 'TZS',
        use24HourTime: json['use24HourTime'] as bool? ?? false,
      );
}
