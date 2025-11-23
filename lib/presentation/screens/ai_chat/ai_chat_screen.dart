import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Импорты ваших файлов (оставляем как есть)
import '../../../core/constants/color_constants.dart';
import '../../../core/services/trip_generation_api.dart';
import '../../../core/services/ai_trips_storage_service.dart';
import 'widgets/ai_generated_trip_view.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showSuggestions = true;
  Map<String, dynamic>? _generatedTrip;
  double _generationProgress = 0.0;

  late AnimationController _welcomeAnimationController;
  late Animation<double> _welcomeFadeAnimation;
  late Animation<Offset> _welcomeSlideAnimation;

  late List<String> _currentSuggestions;

  final List<String> _allPrompts = [
    'Romantic weekend in Paris with Eiffel Tower dinner',
    'Anime and gaming tour in Tokyo for 5 days',
    'Christmas markets tour in Vienna and Prague',
    'Surfing trip to Bali for beginners',
    'Historical Rome tour visiting Colosseum and Vatican',
    'Northern Lights hunting in Tromsø, Norway',
    'Safari adventure in Kenya for 7 days',
    'New York City food and jazz tour',
    'Relaxing spa weekend in Budapest',
    'Hiking the Inca Trail to Machu Picchu',
    'Scuba diving in the Great Barrier Reef',
    'Harry Potter themed trip to London and Scotland',
    'Wine tasting tour in Tuscany, Italy',
    'Cyberpunk style photography tour in Seoul',
    'Backpacking through Thailand islands',
    'Luxury shopping and architecture in Dubai',
    'Road trip through California Highway 1',
    'Skiing vacation in the Swiss Alps',
    'Cherry blossom festival in Kyoto',
    'Game of Thrones filming locations in Croatia',
    'Street food exploration in Mexico City',
    'Techno clubbing weekend in Berlin',
    'Santorini sunset and beach getaway',
    'Coffee and culture trip to Colombia',
    'Lord of the Rings tour in New Zealand',
    'Oktoberfest experience in Munich',
    'Art and museums tour in Amsterdam',
    'Carnival celebration in Rio de Janeiro',
    'Ancient pyramids tour in Cairo, Egypt',
    'Digital nomad workspace trip to Lisbon',
    // --- New 100 Options ---
    // Europe
    'Tapas and flamenco tour in Seville, Spain',
    'Exploring the castles of the Rhine Valley, Germany',
    'Canal boat tour and chocolate tasting in Bruges',
    'Viking history and fjords tour in Oslo & Bergen',
    'Yacht week sailing around Croatian islands',
    'Truffle hunting and gastronomy in Istria',
    'Cinque Terre hiking and village hopping',
    'Dracula myth and castles tour in Transylvania',
    'Whisky distillery trail in the Scottish Highlands',
    'Glass igloo stay to see Aurora in Finland',
    'Moorish architecture tour in Granada and Alhambra',
    'Thermal baths and waterfalls in Iceland',
    'Fashion and design week trip to Milan',
    'Monaco Grand Prix and luxury yacht experience',
    'LEGO House and design tour in Billund, Denmark',
    'Classical music history tour in Salzburg',
    'Cliffs of Moher and pubs tour in Ireland',
    'Exploring the ruins of Pompeii and Amalfi Coast',
    'Balloon ride over Cappadocia landscapes',
    'Midnight Sun film festival in Sodankylä',
    'Perfume making workshop in Grasse, France',
    'Cycling tour through tulip fields in Netherlands',
    'Ghost and mystery tour in Edinburgh',
    'Venice Carnival mask and costume experience',
    'Hiking the Dolomites peaks in Italy',
    'Azores islands nature and whale watching',
    'Greek mythology tour in Athens and Delphi',
    'Cheese and chocolate train ride in Switzerland',
    'Mediterranean diet cooking class in Crete',
    'Opera and ballet night in St. Petersburg',

    // Asia
    'Street food marathon in Penang, Malaysia',
    'Sunrise at Angkor Wat and temple tour',
    'K-Pop dance and culture experience in Seoul',
    'Tea plantation hiking in Sri Lanka',
    'Silk Road history tour in Uzbekistan',
    'Sushi making masterclass in Osaka',
    'Floating markets and temples in Bangkok',
    'Orangutan sanctuary visit in Borneo',
    'Great Wall of China hiking adventure',
    'Yoga and meditation retreat in Rishikesh',
    'Ha Long Bay overnight cruise in Vietnam',
    'Snow monkey park visit in Nagano',
    'Futuristic architecture tour in Singapore',
    'Desert fortress exploration in Rajasthan',
    'Balloons over Bagan temples in Myanmar',
    'Electronic markets and gadgets in Shenzhen',
    'Traditional Ryokan stay with Onsen in Hakone',
    'Spicy food challenge in Chengdu',
    'Exploring the caves of Phong Nha, Vietnam',
    'Mount Fuji climbing expedition',

    // North & Central America
    'Jazz and blues history tour in New Orleans',
    'Mayan ruins exploration in Tikal, Guatemala',
    'Route 66 classic American road trip',
    'Dia de los Muertos festival in Oaxaca',
    'Banff National Park wildlife and lakes',
    'Havana vintage car and cigar tour',
    'Sloth and wildlife sanctuary in Costa Rica',
    'Cenote diving and swimming in Yucatan',
    'Napa Valley wine train and vineyards',
    'Broadway shows and rooftop bars in NYC',
    'Hiking the Grand Canyon rim-to-rim',
    'Volcano hiking tour in Hawaii',
    'French Quarter and poutine in Montreal',
    'Las Vegas casino and entertainment weekend',
    'Exploring Antelope Canyon and Horseshoe Bend',
    'Quebec Winter Carnival experience',
    'Space Center and alligator tour in Florida',
    'Sailing the Florida Keys',
    'Music city tour in Nashville and Memphis',
    'Surfing and yoga retreat in Sayulita',

    // South America
    'Tango lessons and steak dinner in Buenos Aires',
    'Galapagos Islands wildlife cruise',
    'Salar de Uyuni salt flats photography tour',
    'Amazon rainforest riverboat expedition',
    'Patagonia trekking in Torres del Paine',
    'Iguazu Falls boat adventure',
    'Wine harvesting in Mendoza, Argentina',
    'Stargazing in the Atacama Desert',
    'Rio Carnival samba parade experience',
    'Mystery of the Moai statues on Easter Island',
    'Colonial architecture tour in Cartagena',
    'Floating islands of Lake Titicaca',

    // Africa & Middle East
    'Hot air balloon over Luxor and Valley of the Kings',
    'Gorilla trekking experience in Rwanda',
    'Petra by night and Wadi Rum jeep tour',
    'Shopping in the souks of Marrakech',
    'Victoria Falls bungee and helicopter ride',
    'Lemur watching in Madagascar rainforests',
    'Blue City photography tour in Chefchaouen',
    'Luxury desert camping in Oman',
    'Dead Sea floating and wellness trip',
    'Zanzibar spice farm and beach relaxation',
    'Climbing Mount Kilimanjaro',
    'Penguin watching at Boulders Beach, Cape Town',
    'Dune bashing and sandboarding in Dubai',

    // Oceania & Antarctica
    'Great Ocean Road drive in Australia',
    'Hobbiton movie set tour in New Zealand',
    'Snorkeling with manta rays in Fiji',
    'Uluru sunrise and Outback cultural tour',
    'Sydney Opera House and bridge climb',
    'Tasmanian wilderness and devil sanctuary',
    'Overwater bungalow stay in Bora Bora',
    'Glacier helicopter hike in Franz Josef',
    'Antarctica expedition cruise',
    'Rottnest Island quokka selfie tour',

    // Special Interest / Niche
    'Formula 1 Grand Prix weekend in Monaco',
    'Digital nomad co-living in Canggu, Bali',
    'Sustainable eco-lodge stay in Costa Rica',
    'Visiting all Disney parks in Orlando',
    'Historical WWII tour in Normandy',
    'Trans-Siberian Railway journey',
  ];

  @override
  void initState() {
    super.initState();

    _currentSuggestions = List.from(_allPrompts)..shuffle();
    _currentSuggestions = _currentSuggestions.take(4).toList();

    _welcomeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _welcomeFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _welcomeAnimationController,
      curve: Curves.easeOutQuart,
    ));

    _welcomeSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _welcomeAnimationController,
      curve: Curves.easeOutQuart,
    ));

    Future.delayed(const Duration(milliseconds: 100), () {
      _welcomeAnimationController.forward();
    });

    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty && _showSuggestions) {
        setState(() => _showSuggestions = false);
      } else if (_messageController.text.isEmpty && !_showSuggestions) {
        setState(() => _showSuggestions = true);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _welcomeAnimationController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _showSuggestions = false;
      _messages.add(ChatMessage(
        text: messageText,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
      _generationProgress = 0.0;
    });

    _scrollToBottom();
    _generateTripFromMessage(messageText);
  }

  void _handleSuggestionTap(String suggestion) {
    // Небольшая задержка для визуального эффекта нажатия
    Future.delayed(const Duration(milliseconds: 150), () {
      _messageController.text = suggestion;
      _sendMessage();
    });
  }

  Future<void> _generateTripFromMessage(String userMessage) async {
    try {
      _animateProgress();

      final trip = await TripGenerationApi.generateFlexibleTrip(
        query: userMessage,
      );

      trip['original_query'] = userMessage;
      await AiTripsStorageService.saveTrip(trip);

      if (mounted) {
        setState(() {
          _generationProgress = 1.0;
          _generatedTrip = trip;
          _isTyping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Sorry, I encountered an error: ${e.toString()}',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
          _generationProgress = 0.0;
        });
      }
    }
  }

  void _animateProgress() {
    _generationProgress = 0.0;

    final progressSteps = [0.15, 0.35, 0.55, 0.75, 0.90];
    final delays = [500, 800, 1000, 1200, 800];

    for (int i = 0; i < progressSteps.length; i++) {
      Future.delayed(
          Duration(milliseconds: delays.take(i + 1).reduce((a, b) => a + b)),
          () {
        if (mounted && _isTyping) {
          setState(() {
            _generationProgress = progressSteps[i];
          });
        }
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_generatedTrip != null) {
      return AiGeneratedTripView(
        trip: _generatedTrip!,
        onBack: () {
          setState(() {
            _generatedTrip = null;
            _messages.clear();
            _showSuggestions = true;
          });
        },
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: AppColors.darkBackground,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              // Main content
              Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? _buildWelcomeScreen()
                        : SafeArea(
                            bottom: false,
                            child: _buildMessagesList(),
                          ),
                  ),
                  if (_messages.isNotEmpty) const SizedBox(height: 100),
                ],
              ),

              // Header
              if (_messages.isEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          Expanded(
                            child: FadeTransition(
                              opacity: _welcomeFadeAnimation,
                              child: Text(
                                'Plan Your Perfect Trip',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 36),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

              // Input Area
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: _buildInputArea(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return FadeTransition(
      opacity: _welcomeFadeAnimation,
      child: SlideTransition(
        position: _welcomeSlideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 130),
              Text(
                'Tell me where you want to go, and I\'ll create a personalized itinerary',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_showSuggestions) _buildVerticalSuggestions(),
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalSuggestions() {
    return Container(
      width: double.infinity,
      child: Column(
        children: List.generate(_currentSuggestions.length, (index) {
          final isFirst = index == 0;
          final isLast = index == _currentSuggestions.length - 1;

          final borderRadius = BorderRadius.vertical(
            top: isFirst ? const Radius.circular(24) : Radius.zero,
            bottom: isLast ? const Radius.circular(24) : Radius.zero,
          );

          return Column(
            children: [
              BounceableButton(
                onTap: () => _handleSuggestionTap(_currentSuggestions[index]),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: borderRadius,
                  ),
                  child: Text(
                    _currentSuggestions[index],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  height: 1,
                  color: Colors.black.withValues(alpha: 0.2),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const _TypingAnimation(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Generating your trip...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(_generationProgress * 100).toInt()}%',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 4,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      tween: Tween<double>(
                        begin: 0,
                        end: _generationProgress,
                      ),
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.darkBackground.withValues(alpha: 0.0),
            AppColors.darkBackground,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 44,
                maxHeight: 100,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardAppearance: Brightness.dark,
                      decoration: InputDecoration(
                        hintText: 'Romantic weekend in Paris ',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: BounceableButton(
                      onTap: () {
                        // TODO: Voice input
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          BounceableButton(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward,
                color: Colors.black,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// REUSABLE BOUNCE ANIMATION WIDGET (FIXED WITH LISTENER)
// ══════════════════════════════════════════════════════════════════════════

class BounceableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BounceableButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<BounceableButton> createState() => _BounceableButtonState();
}

class _BounceableButtonState extends State<BounceableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Ускорили длительность анимации нажатия для большей отзывчивости
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _controller.forward().then((_) => _controller.reverse());
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// MESSAGE MODEL & TYPING ANIMATION
// ══════════════════════════════════════════════════════════════════════════

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _TypingAnimation extends StatefulWidget {
  const _TypingAnimation();

  @override
  State<_TypingAnimation> createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<_TypingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final progress = (_controller.value - delay) % 1.0;
            final opacity = progress < 0.5 ? progress * 2 : 2 - (progress * 2);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity.clamp(0.3, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
