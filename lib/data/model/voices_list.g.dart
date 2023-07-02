// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voices_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoicesList _$VoicesListFromJson(Map<String, dynamic> json) => VoicesList(
      name: json['Name'] as String? ?? '',
      shortName: json['ShortName'] as String? ?? '',
      gender: json['Gender'] as String? ?? '',
      locale: json['Locale'] as String? ?? '',
      suggestedCodec: json['SuggestedCodec'] as String? ?? '',
      friendlyName: json['FriendlyName'] as String? ?? '',
      status: json['Status'] as String? ?? '',
      voiceTag: VoiceTag.fromJson(json['VoiceTag'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VoicesListToJson(VoicesList instance) =>
    <String, dynamic>{
      'Name': instance.name,
      'ShortName': instance.shortName,
      'Gender': instance.gender,
      'Locale': instance.locale,
      'SuggestedCodec': instance.suggestedCodec,
      'FriendlyName': instance.friendlyName,
      'Status': instance.status,
      'VoiceTag': instance.voiceTag.toJson(),
    };

VoiceTag _$VoiceTagFromJson(Map<String, dynamic> json) => VoiceTag(
      contentCategories: (json['ContentCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      voicePersonalities: (json['VoicePersonalities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$VoiceTagToJson(VoiceTag instance) => <String, dynamic>{
      'ContentCategories': instance.contentCategories,
      'VoicePersonalities': instance.voicePersonalities,
    };
