class EmergencyContact {
  final String name;
  final String phoneNumber;
  final String relation;

  EmergencyContact({
    required this.name,
    required this.phoneNumber,
    required this.relation,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relation': relation,
    };
  }

  // Create from JSON
  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      relation: json['relation'] as String,
    );
  }
}
