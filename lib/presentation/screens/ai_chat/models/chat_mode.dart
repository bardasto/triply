/// Enum representing the current mode of the AI chat.
enum ChatMode {
  tripGeneration(
    'Trip Generation',
    'Where to?',
    "What would you like me to generate for you today? Just describe your dream trip and I'll create a personalized itinerary!",
  ),
  hotelSelection(
    'Hotel Selection',
    'Find Your Stay',
    "Let me help you find the perfect hotel! Tell me your destination, dates, and preferences, and I'll find great options for you.",
  ),
  flightTickets(
    'Flight Tickets',
    'Book Your Flight',
    "Ready to fly? Tell me where you're heading, your travel dates, and any preferences, and I'll help you find the best flights!",
  );

  final String label;
  final String headerTitle;
  final String welcomeMessage;

  const ChatMode(this.label, this.headerTitle, this.welcomeMessage);
}
