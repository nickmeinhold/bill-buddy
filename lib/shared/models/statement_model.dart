import 'package:equatable/equatable.dart';

enum StatementStatus { uploading, processing, completed, failed }

class StatementModel extends Equatable {
  final String id;
  final String fileName;
  final DateTime uploadedAt;
  final StatementStatus status;
  final int? transactionCount;
  final String? errorMessage;
  final String storagePath;

  const StatementModel({
    required this.id,
    required this.fileName,
    required this.uploadedAt,
    required this.status,
    this.transactionCount,
    this.errorMessage,
    required this.storagePath,
  });

  bool get isProcessing => status == StatementStatus.processing;
  bool get isCompleted => status == StatementStatus.completed;
  bool get isFailed => status == StatementStatus.failed;

  factory StatementModel.fromMap(Map<String, dynamic> map, String id) {
    return StatementModel(
      id: id,
      fileName: map['fileName'] as String,
      uploadedAt: DateTime.parse(map['uploadedAt'] as String),
      status: StatementStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StatementStatus.processing,
      ),
      transactionCount: map['transactionCount'] as int?,
      errorMessage: map['errorMessage'] as String?,
      storagePath: map['storagePath'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'uploadedAt': uploadedAt.toIso8601String(),
      'status': status.name,
      'transactionCount': transactionCount,
      'errorMessage': errorMessage,
      'storagePath': storagePath,
    };
  }

  StatementModel copyWith({
    String? id,
    String? fileName,
    DateTime? uploadedAt,
    StatementStatus? status,
    int? transactionCount,
    String? errorMessage,
    String? storagePath,
  }) {
    return StatementModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      status: status ?? this.status,
      transactionCount: transactionCount ?? this.transactionCount,
      errorMessage: errorMessage ?? this.errorMessage,
      storagePath: storagePath ?? this.storagePath,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fileName,
        uploadedAt,
        status,
        transactionCount,
        errorMessage,
        storagePath,
      ];
}
