import 'dart:convert';
import 'package:intl/intl.dart';

class MemoModel {
  final int? id;
  final String title;
  final String content;
  final List<String> images; // 本地路径列表
  final DateTime createdAt;
  final DateTime updatedAt;

  MemoModel({this.id, required this.title, this.content = '', this.images = const [], DateTime? createdAt, DateTime? updatedAt})
    : createdAt = createdAt ?? DateTime.now(), updatedAt = updatedAt ?? DateTime.now();

  String get formattedDate => DateFormat('MM/dd HH:mm').format(updatedAt);
  String get preview => content.length > 50 ? '${content.substring(0, 50)}...' : content;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'title': title, 'content': content,
    'images': jsonEncode(images), 'created_at': createdAt.millisecondsSinceEpoch, 'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory MemoModel.fromMap(Map<String, dynamic> m) => MemoModel(
    id: m['id'] as int?, title: m['title'] as String, content: m['content'] as String? ?? '',
    images: (() { try { return (jsonDecode(m['images'] as String? ?? '[]') as List).cast<String>(); } catch (_) { return <String>[]; }})(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int), updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
  );

  MemoModel copyWith({int? id, String? title, String? content, List<String>? images, DateTime? createdAt, DateTime? updatedAt}) =>
    MemoModel(id: id ?? this.id, title: title ?? this.title, content: content ?? this.content,
      images: images ?? this.images, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt);
}
