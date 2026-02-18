import 'package:json_annotation/json_annotation.dart';

part 'external_link.g.dart';

@JsonSerializable()
class ExternalLink {
  final String label;
  final String url;

  const ExternalLink({required this.label, required this.url});

  factory ExternalLink.fromJson(Map<String, dynamic> json) =>
      _$ExternalLinkFromJson(json);

  Map<String, dynamic> toJson() => _$ExternalLinkToJson(this);

  ExternalLink copyWith({String? label, String? url}) => ExternalLink(
        label: label ?? this.label,
        url: url ?? this.url,
      );
}
