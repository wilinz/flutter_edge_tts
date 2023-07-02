import 'package:json_annotation/json_annotation.dart';

part 'voices_list.g.dart';

List<VoicesList> voicesListListFormJson(List<Map<String, dynamic>> json) =>
    json.map((e) => VoicesList.fromJson(e)).toList();

List<Map<String, dynamic>> voicesListListToJson(List<VoicesList> instance) =>
    instance.map((e) => e.toJson()).toList();

@JsonSerializable(explicitToJson: true)
class VoicesList {
  VoicesList(
      {required this.name,
      required this.shortName,
      required this.gender,
      required this.locale,
      required this.suggestedCodec,
      required this.friendlyName,
      required this.status,
      required this.voiceTag});

  @JsonKey(name: "Name", defaultValue: "")
  String name;
  @JsonKey(name: "ShortName", defaultValue: "")
  String shortName;
  @JsonKey(name: "Gender", defaultValue: "")
  String gender;
  @JsonKey(name: "Locale", defaultValue: "")
  String locale;
  @JsonKey(name: "SuggestedCodec", defaultValue: "")
  String suggestedCodec;
  @JsonKey(name: "FriendlyName", defaultValue: "")
  String friendlyName;
  @JsonKey(name: "Status", defaultValue: "")
  String status;
  @JsonKey(name: "VoiceTag")
  VoiceTag voiceTag;

  factory VoicesList.fromJson(Map<String, dynamic> json) => _$VoicesListFromJson(json);

  Map<String, dynamic> toJson() => _$VoicesListToJson(this);
}

@JsonSerializable(explicitToJson: true)
class VoiceTag {
  VoiceTag(
      {required this.contentCategories,
      required this.voicePersonalities});

  @JsonKey(name: "ContentCategories", defaultValue: [])
  List<String> contentCategories;
  @JsonKey(name: "VoicePersonalities", defaultValue: [])
  List<String> voicePersonalities;

  factory VoiceTag.fromJson(Map<String, dynamic> json) => _$VoiceTagFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceTagToJson(this);
}


