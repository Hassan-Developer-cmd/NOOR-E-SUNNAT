import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String question;
  final String category;
  final String status; // 'Pending' | 'Answered'
  final String? answer;
  final String? answeredBy;
  final DateTime? answeredAt;
  final DateTime? createdAt;
  final bool isPublic;
  final bool isDeletedByUser;

  const QuestionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.question,
    required this.category,
    this.status = 'Pending',
    this.answer,
    this.answeredBy,
    this.answeredAt,
    this.createdAt,
    this.isPublic = false,
    this.isDeletedByUser = false,
  });

  bool get isAnswered => status.toLowerCase() == 'answered';
  bool get isPending => status.toLowerCase() == 'pending';

  static const List<String> supportedCategories = [
    'Namaz',
    'Wuzu',
    'Roza',
    'Zakat',
    'Hajj',
    'Taharat',
    'Nikah',
    'Aqaid',
    'General',
  ];

  static String getCategoryUrdu(String cat) {
    switch (cat.toLowerCase()) {
      case 'namaz':
        return 'نماز';
      case 'wuzu':
        return 'وضو';
      case 'roza':
        return 'روزہ';
      case 'zakat':
        return 'زکوٰۃ';
      case 'hajj':
        return 'حج و عمرہ';
      case 'taharat':
        return 'طہارت و پاکی';
      case 'nikah':
        return 'نکاح و طلاق';
      case 'aqaid':
        return 'عقائد';
      case 'general':
      default:
        return 'عام مسائل';
    }
  }

  factory QuestionModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? createdTime;
    if (map['created_at'] is Timestamp) {
      createdTime = (map['created_at'] as Timestamp).toDate();
    } else if (map['created_at'] is String) {
      createdTime = DateTime.tryParse(map['created_at'] as String);
    }

    DateTime? answeredTime;
    if (map['answered_at'] is Timestamp) {
      answeredTime = (map['answered_at'] as Timestamp).toDate();
    } else if (map['answered_at'] is String) {
      answeredTime = DateTime.tryParse(map['answered_at'] as String);
    }

    return QuestionModel(
      id: id,
      userId: map['user_id'] as String? ?? '',
      userName: map['user_name'] as String? ?? 'Anonymous',
      userEmail: map['user_email'] as String? ?? '',
      question: map['question'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      status: map['status'] as String? ?? 'Pending',
      answer: map['answer'] as String?,
      answeredBy: map['answered_by'] as String?,
      answeredAt: answeredTime,
      createdAt: createdTime,
      isPublic: map['is_public'] as bool? ?? false,
      isDeletedByUser: map['is_deleted_by_user'] as bool? ??
          map['deleted_by_user'] as bool? ??
          false,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'question': question,
        'category': category,
        'status': status,
        'answer': answer,
        'answered_by': answeredBy,
        'answered_at': answeredAt != null ? Timestamp.fromDate(answeredAt!) : null,
        'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
        'is_public': isPublic,
        'is_deleted_by_user': isDeletedByUser,
      };

  QuestionModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? question,
    String? category,
    String? status,
    String? answer,
    String? answeredBy,
    DateTime? answeredAt,
    DateTime? createdAt,
    bool? isPublic,
    bool? isDeletedByUser,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      question: question ?? this.question,
      category: category ?? this.category,
      status: status ?? this.status,
      answer: answer ?? this.answer,
      answeredBy: answeredBy ?? this.answeredBy,
      answeredAt: answeredAt ?? this.answeredAt,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      isDeletedByUser: isDeletedByUser ?? this.isDeletedByUser,
    );
  }
}
