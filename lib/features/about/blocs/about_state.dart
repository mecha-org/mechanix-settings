import 'package:equatable/equatable.dart';
import 'package:mechanix_settings/features/about/data/models/about_details.dart';
import 'package:mechanix_settings/features/about/data/models/enums.dart';

class AboutState extends Equatable {
  final AboutStatus status;
  final AboutDetails? details;
  final AboutError? error;

  const AboutState({
    this.status = AboutStatus.initial,
    this.details,
    this.error,
  });

  AboutState copyWith({
    AboutStatus? status,
    AboutDetails? details,
    AboutError? error,
  }) {
    return AboutState(
      status: status ?? this.status,
      details: details ?? this.details,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, details, error];
}
