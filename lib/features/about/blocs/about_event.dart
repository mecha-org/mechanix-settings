import 'package:equatable/equatable.dart';

abstract class AboutEvent extends Equatable {
  const AboutEvent();

  @override
  List<Object?> get props => [];
}

class LoadAboutDetails extends AboutEvent {
  const LoadAboutDetails();
}

class UpdateDeviceName extends AboutEvent {
  final String name;

  const UpdateDeviceName(this.name);

  @override
  List<Object?> get props => [name];
}

class UpdateHostname extends AboutEvent {
  final String hostname;

  const UpdateHostname(this.hostname);

  @override
  List<Object?> get props => [hostname];
}
