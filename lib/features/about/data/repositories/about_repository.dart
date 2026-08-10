import 'package:mechanix_settings/features/about/data/models/about_details.dart';

abstract class AboutRepository {
  Future<AboutDetails> getAboutDetails();

  Future<void> updateDeviceName(String name);

  Future<void> updateHostname(String hostname);
}
