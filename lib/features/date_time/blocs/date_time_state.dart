import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:mechanix_settings/core/constants/date_time.dart';
import 'package:mechanix_settings/features/date_time/data/models/enums.dart';

class DateTimeState extends Equatable {
  final bool autoTime;
  final String timezone;
  final int hour;
  final int minute;
  final bool isAm;
  final int year;
  final int month;
  final int day;
  final String timeFormat;

  final DateTimeStatus status;
  final DateTimeError? error;

  const DateTimeState({
    required this.autoTime,
    required this.timezone,
    required this.hour,
    required this.minute,
    required this.isAm,
    required this.year,
    required this.month,
    required this.day,
    required this.timeFormat,
    required this.status,
    this.error,
  });

  factory DateTimeState.initial() {
    final now = DateTime.now();

    return DateTimeState(
      autoTime: true,
      timezone: "",
      hour: int.parse(DateFormat("h").format(now)),
      minute: now.minute,
      isAm: now.hour < 12,
      year: now.year,
      month: now.month,
      day: now.day,
      timeFormat: TimeFormats.hour12,
      status: DateTimeStatus.initial,
    );
  }

  DateTimeState copyWith({
    bool? autoTime,
    String? timezone,
    int? hour,
    int? minute,
    bool? isAm,
    int? year,
    int? month,
    int? day,
    String? timeFormat,
    DateTimeStatus? status,
    DateTimeError? error,
  }) {
    return DateTimeState(
      autoTime: autoTime ?? this.autoTime,
      timezone: timezone ?? this.timezone,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isAm: isAm ?? this.isAm,
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      timeFormat: timeFormat ?? this.timeFormat,
      status: status ?? this.status,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    autoTime,
    timezone,
    hour,
    minute,
    isAm,
    year,
    month,
    day,
    timeFormat,
    status,
    error,
  ];
}
