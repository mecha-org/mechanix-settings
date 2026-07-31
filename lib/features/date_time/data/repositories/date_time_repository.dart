import 'dart:async';

abstract class DateTimeRepository {
  Future<void> init();
  Future<bool> getNtpEnabled();
  Future<void> setNtpEnabled(bool enabled);
  Future<String> getTimezone();
  Future<void> setTimezone(String timezone);
  Future<void> setTime(int microsecondsSinceEpoch);
  Future<DateTime> getSystemTime();
  Stream<List<String>> get propertiesChangedStream;
  Future<void> close();
  Future<String> getTimeFormat();
  Future<void> setTimeFormat(String format);
}
