class WeatherSnapshot {
  final int weatherCode;
  final double? temperature;
  final String category;

  const WeatherSnapshot({
    required this.weatherCode,
    required this.category,
    this.temperature,
  });
}
