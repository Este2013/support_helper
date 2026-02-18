import 'answer_destination.dart';

class Answer {
  final String label;
  final String? notes;
  final AnswerDestination destination;

  const Answer({
    required this.label,
    this.notes,
    required this.destination,
  });

  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
        label: json['label'] as String,
        notes: json['notes'] as String?,
        destination: AnswerDestination.fromJson(
            json['destination'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        if (notes != null) 'notes': notes,
        'destination': destination.toJson(),
      };

  Answer copyWith({
    String? label,
    String? notes,
    AnswerDestination? destination,
  }) =>
      Answer(
        label: label ?? this.label,
        notes: notes ?? this.notes,
        destination: destination ?? this.destination,
      );
}
