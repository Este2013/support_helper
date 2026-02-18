import 'package:json_annotation/json_annotation.dart';

part 'python_output.g.dart';

@JsonSerializable()
class PythonScriptOutput {
  @JsonKey(name: 'suggested_answer')
  final String? suggestedAnswer;
  final String? notes;

  const PythonScriptOutput({this.suggestedAnswer, this.notes});

  factory PythonScriptOutput.fromJson(Map<String, dynamic> json) =>
      _$PythonScriptOutputFromJson(json);

  Map<String, dynamic> toJson() => _$PythonScriptOutputToJson(this);
}
