// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'python_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PythonScriptInput _$PythonScriptInputFromJson(Map<String, dynamic> json) =>
    PythonScriptInput(
      attachments: (json['attachments'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      storedAnswers: Map<String, String>.from(json['stored_answers'] as Map),
    );

Map<String, dynamic> _$PythonScriptInputToJson(PythonScriptInput instance) =>
    <String, dynamic>{
      'attachments': instance.attachments,
      'stored_answers': instance.storedAnswers,
    };
