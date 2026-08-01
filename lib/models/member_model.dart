class MemberModel {
  final String name;
  final String phone;
  final String membershipNumber;

  MemberModel({
    required this.name,
    required this.phone,
    required this.membershipNumber,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'phone': phone, 'membershipNumber': membershipNumber};
  }

  factory MemberModel.fromMap(Map<String, dynamic> map) {
    return MemberModel(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      membershipNumber: map['membershipNumber'] ?? '',
    );
  }
}
