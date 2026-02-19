import 'card_data.dart';

class Profile {
  String id;
  String name;
  CardData data;

  Profile({
    required this.id,
    required this.name,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'data': data.toJson(),
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      name: json['name'],
      data: CardData.fromJson(json['data']),
    );
  }
}
