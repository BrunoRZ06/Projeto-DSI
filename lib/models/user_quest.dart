import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Mapa de nomes de ícone → IconData para quests criadas pelo usuário.
const Map<String, IconData> questIconOptions = {
  'star': LucideIcons.star,
  'camera': LucideIcons.camera,
  'coffee': LucideIcons.coffee,
  'landmark': LucideIcons.landmark,
  'music': LucideIcons.music,
  'map': LucideIcons.map,
  'heart': LucideIcons.heart,
  'flag': LucideIcons.flag,
  'trophy': LucideIcons.trophy,
  'book': LucideIcons.book,
  'bike': LucideIcons.bike,
  'utensils': LucideIcons.utensils,
};

IconData iconFromName(String name) =>
    questIconOptions[name] ?? LucideIcons.star;

class UserQuest {
  final String id;
  final String userId;
  final String title;
  final String subtitle;
  final String details;
  final int xp;
  final String iconName;
  final String? photoUrl;
  final String? cityName; // Cidade associada à quest
  final DateTime? createdAt;

  const UserQuest({
    required this.id,
    required this.userId,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.xp,
    required this.iconName,
    this.photoUrl,
    this.cityName,
    this.createdAt,
  });

  IconData get icon => iconFromName(iconName);

  factory UserQuest.fromMap(Map<String, dynamic> map) {
    return UserQuest(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String? ?? '',
      details: map['details'] as String? ?? '',
      xp: map['xp'] as int? ?? 100,
      iconName: map['icon_name'] as String? ?? 'star',
      photoUrl: map['photo_url'] as String?,
      cityName: map['city_name'] as String?,
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : map['created_at'] is String
              ? DateTime.tryParse(map['created_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'title': title,
        'subtitle': subtitle,
        'details': details,
        'xp': xp,
        'icon_name': iconName,
        'photo_url': photoUrl,
        'city_name': cityName,
      };

  Map<String, dynamic> toJson() => toMap();

  factory UserQuest.fromJson(Map<String, dynamic> json) => UserQuest.fromMap(json);

  UserQuest copyWith({
    String? title,
    String? subtitle,
    String? details,
    int? xp,
    String? iconName,
    String? photoUrl,
    String? cityName,
    DateTime? createdAt,
  }) {
    return UserQuest(
      id: id,
      userId: userId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      details: details ?? this.details,
      xp: xp ?? this.xp,
      iconName: iconName ?? this.iconName,
      photoUrl: photoUrl ?? this.photoUrl,
      cityName: cityName ?? this.cityName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
