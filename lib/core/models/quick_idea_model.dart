class QuickIdeaModel {
  final String id;
  final String title;
  final String description;
  final String destination;
  final int duration;
  final double estimatedPrice;
  final String currency;
  final String type;

  const QuickIdeaModel({
    required this.id,
    required this.title,
    required this.description,
    required this.destination,
    required this.duration,
    required this.estimatedPrice,
    this.currency = 'EUR',
    required this.type,
  });
}
