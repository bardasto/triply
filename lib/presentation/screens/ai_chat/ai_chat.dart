/// AI Chat module exports.
///
/// Provides a modular architecture for the AI chat screen.
///
/// Usage:
/// ```dart
/// import 'ai_chat/ai_chat.dart';
///
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => const AiChatScreen()),
/// );
/// ```
library ai_chat;

// Main screen
export 'ai_chat_screen.dart';

// Controller
export 'controller/ai_chat_controller.dart';

// Models
export 'models/chat_message.dart';
export 'models/chat_history.dart';
export 'models/chat_mode.dart';

// Theme
export 'theme/ai_chat_theme.dart';
export 'theme/ai_chat_prompts.dart';

// Common widgets
export 'widgets/common/bounceable_button.dart';
export 'widgets/common/typing_animation.dart';
export 'widgets/common/circle_button.dart';
export 'widgets/common/typewriter_text.dart';

// Chat widgets
export 'widgets/chat/chat_header.dart';
export 'widgets/chat/chat_input.dart';
export 'widgets/chat/message_bubble.dart';
export 'widgets/chat/suggestion_list.dart';
export 'widgets/chat/typing_indicator.dart';

// Sidebar widgets
export 'widgets/sidebar/chat_sidebar.dart';
export 'widgets/sidebar/sidebar_button.dart';
export 'widgets/sidebar/history_item.dart';

// Trip card widgets
export 'widgets/trip_card/generated_trip_card.dart';
export 'widgets/trip_card/trip_card_image_carousel.dart';

// AI Generated Trip View
export 'widgets/ai_generated_trip_view.dart';
