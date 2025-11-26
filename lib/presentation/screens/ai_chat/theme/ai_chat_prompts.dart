/// Collection of trip suggestion prompts for the AI chat.
class AiChatPrompts {
  AiChatPrompts._();

  static const List<String> allPrompts = [
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

  /// Returns a shuffled list of random suggestions.
  static List<String> getRandomSuggestions({int count = 4}) {
    final shuffled = List<String>.from(allPrompts)..shuffle();
    return shuffled.take(count).toList();
  }

  /// Trip completion messages shown after generation.
  static List<String> getCompletionMessages(String location) {
    return [
      "Here's your trip to $location! I've crafted a wonderful itinerary for you. Would you like to make any changes?",
      "Your adventure to $location is ready! Take a look at what I've planned. Feel free to let me know if you'd like any adjustments!",
      "I've put together an amazing trip to $location just for you! Is there anything you'd like me to modify?",
      "Here's your personalized $location experience! Let me know if you want to tweak anything.",
      "Your $location journey awaits! I hope you love it. Want me to change anything?",
      "Ta-da! Your trip to $location is all set. Would you like to customize it further?",
    ];
  }

  /// Returns a random completion message.
  static String getRandomCompletionMessage(String location) {
    final messages = getCompletionMessages(location);
    messages.shuffle();
    return messages.first;
  }

  /// Trip modification messages shown after updating a trip.
  static List<String> getModificationMessages(String location) {
    return [
      "Done! I've updated your $location trip as requested. Take a look at the changes!",
      "Your $location trip has been modified! Let me know if you'd like any more adjustments.",
      "I've made the changes to your $location itinerary. What do you think?",
      "All set! Your updated $location trip is ready. Want me to tweak anything else?",
      "Here's your revised $location adventure! Feel free to ask for more changes.",
    ];
  }

  /// Returns a random modification message.
  static String getRandomModificationMessage(String location) {
    final messages = getModificationMessages(location);
    messages.shuffle();
    return messages.first;
  }
}
