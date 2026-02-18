import 'package:json_annotation/json_annotation.dart';

part 'python_input.g.dart';

@JsonSerializable()
class PythonScriptInput {
  final List<String> attachments;
  @JsonKey(name: 'stored_answers')
  final Map<String, String> storedAnswers;

  const PythonScriptInput({
    required this.attachments,
    required this.storedAnswers,
  });

  factory PythonScriptInput.fromJson(Map<String, dynamic> json) =>
      _$PythonScriptInputFromJson(json);

  Map<String, dynamic> toJson() => _$PythonScriptInputToJson(this);
}
