class AboutDetails {
  final String deviceName;
  final String hostname;
  final String model;
  final String manufacturer;
  final String operatingSystem;
  final String supportUntil;
  final String kernel;
  final String kernelBuild;
  final String firmwareVersion;
  final String firmwareVendor;
  final String firmwareDate;
  final String? serialNumber;
  final String machineId;
  final String bootId;
  final String osWebsite;

  const AboutDetails({
    required this.deviceName,
    required this.hostname,
    required this.model,
    required this.manufacturer,
    required this.operatingSystem,
    required this.supportUntil,
    required this.kernel,
    required this.kernelBuild,
    required this.firmwareVersion,
    required this.firmwareVendor,
    required this.firmwareDate,
    this.serialNumber,
    required this.machineId,
    required this.bootId,
    required this.osWebsite,
  });
}
