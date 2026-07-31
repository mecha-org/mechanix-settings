import 'package:equatable/equatable.dart';

abstract class DateTimeEvent extends Equatable {
  const DateTimeEvent();

  @override
  List<Object?> get props => [];
}

class ToggleAutoTimeEvent extends DateTimeEvent {
  final bool value;
  const ToggleAutoTimeEvent(this.value);

  @override
  List<Object?> get props => [value];
}

class UpdateTimezoneEvent extends DateTimeEvent {
  final String timezone;
  const UpdateTimezoneEvent(this.timezone);

  @override
  List<Object?> get props => [timezone];
}

class UpdateTimeEvent extends DateTimeEvent {
  final int hour;
  final int minute;
  final bool isAm;
  const UpdateTimeEvent(this.hour, this.minute, this.isAm);

  @override
  List<Object?> get props => [hour, minute, isAm];
}

class UpdateDateEvent extends DateTimeEvent {
  final int year;
  final int month;
  final int day;
  const UpdateDateEvent(this.year, this.month, this.day);

  @override
  List<Object?> get props => [year, month, day];
}

class UpdateTimeFormatEvent extends DateTimeEvent {
  final String timeFormat;
  const UpdateTimeFormatEvent(this.timeFormat);

  @override
  List<Object?> get props => [timeFormat];
}

class UpdateDateFormatEvent extends DateTimeEvent {
  final String dateFormat;
  const UpdateDateFormatEvent(this.dateFormat);

  @override
  List<Object?> get props => [dateFormat];
}

class InitializeDateTimeEvent extends DateTimeEvent {
  const InitializeDateTimeEvent();

  @override
  List<Object?> get props => [];
}

class RefreshDateTimeEvent extends DateTimeEvent {
  const RefreshDateTimeEvent();

  @override
  List<Object?> get props => [];
}
