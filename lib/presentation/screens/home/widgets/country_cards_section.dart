// import 'dart:ui';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../../core/constants/color_constants.dart';
// import '../../../../core/models/country_model.dart';
// import '../../../../core/data/repositories/trip_repository.dart';
// import '../date_selection_dialog.dart';

// class CountryCardsSection extends StatefulWidget {
//   final String selectedContinent;
//   final bool isDarkMode; // ✅ ДОБАВЛЕНО

//   const CountryCardsSection({
//     Key? key,
//     required this.selectedContinent,
//     required this.isDarkMode, // ✅ ДОБАВЛЕНО
//   }) : super(key: key);

//   @override
//   State<CountryCardsSection> createState() => _CountryCardsSectionState();
// }

// class _CountryCardsSectionState extends State<CountryCardsSection>
//     with TickerProviderStateMixin {
//   // ✅ КОНСТАНТЫ
//   static const int _initialIndex = 10000;
//   static const Duration _animationDuration = Duration(milliseconds: 350);
//   static const Duration _sideCardsAnimationDuration =
//       Duration(milliseconds: 60);
//   static const double _swipeThresholdRatio = 0.3;
//   static const double _velocityThreshold = 300.0;
//   static const double _cardWidthRatio = 0.75;
//   static const double _cardHeight = 450.0;

//   // ✅ СОСТОЯНИЕ
//   int _currentIndex = _initialIndex;
//   double _dragOffset = 0.0;
//   List<CountryModel> _countries = [];
//   bool _isLoading = true;

//   // ✅ АНИМАЦИИ
//   late AnimationController _animationController;
//   late Animation<Offset> _offsetAnimation;
//   late AnimationController _sideCardsController;
//   late Animation<double> _sideCardsAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _loadCountries();
//   }

//   @override
//   void didUpdateWidget(CountryCardsSection oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.selectedContinent != widget.selectedContinent) {
//       _resetCards();
//       _loadCountries();
//     }
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _sideCardsController.dispose();
//     super.dispose();
//   }

//   // ══════════════════════════════════════════════════════════════════════════
//   // ✅ ИНИЦИАЛИЗАЦИЯ
//   // ══════════════════════════════════════════════════════════════════════════

//   void _initializeAnimations() {
//     _animationController = AnimationController(
//       vsync: this,
//       duration: _animationDuration,
//     );

//     _offsetAnimation = Tween<Offset>(
//       begin: Offset.zero,
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));

//     _sideCardsController = AnimationController(
//       vsync: this,
//       duration: _sideCardsAnimationDuration,
//     );

//     _sideCardsAnimation = CurvedAnimation(
//       parent: _sideCardsController,
//       curve: Curves.easeOutCubic,
//     );

//     _sideCardsController.forward();
//   }

//   Future<void> _loadCountries() async {
//     setState(() => _isLoading = true);

//     try {
//       final tripRepository = TripRepository();
//       final countries = await tripRepository
//           .getCountriesByContinent(widget.selectedContinent);

//       if (mounted) {
//         setState(() {
//           _countries = countries;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('❌ Error loading countries: $e');
//       if (mounted) {
//         setState(() {
//           _countries = [];
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   void _resetCards() {
//     setState(() {
//       _currentIndex = _initialIndex;
//       _dragOffset = 0.0;
//     });
//     _sideCardsController.forward(from: 0);
//   }

//   // ══════════════════════════════════════════════════════════════════════════
//   // ✅ ОБРАБОТКА СВАЙПОВ
//   // ══════════════════════════════════════════════════════════════════════════

//   void _onPanUpdate(DragUpdateDetails details) {
//     setState(() {
//       _dragOffset += details.delta.dx;
//       _offsetAnimation = Tween<Offset>(
//         begin: _offsetAnimation.value,
//         end: _offsetAnimation.value + Offset(details.delta.dx, 0),
//       ).animate(_animationController);
//       _animationController.value = 1.0;
//     });
//   }

//   void _onPanEnd(DragEndDetails details, double screenWidth) {
//     final velocity = details.velocity.pixelsPerSecond.dx;
//     final swipeThreshold = screenWidth * _swipeThresholdRatio;

//     if (velocity.abs() > _velocityThreshold ||
//         _offsetAnimation.value.dx.abs() > swipeThreshold) {
//       if (_offsetAnimation.value.dx > 0 || velocity > _velocityThreshold) {
//         _performSwipe(screenWidth, isRight: true);
//       } else {
//         _performSwipe(screenWidth, isRight: false);
//       }
//     } else {
//       _animationController.reverse().then((_) {
//         setState(() => _dragOffset = 0.0);
//       });
//     }
//   }

//   void _performSwipe(double screenWidth, {required bool isRight}) {
//     final direction = isRight ? 1.5 : -1.5;

//     _offsetAnimation = Tween<Offset>(
//       begin: _offsetAnimation.value,
//       end: Offset(screenWidth * direction, 0),
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));

//     _animationController.forward(from: 0).then((_) {
//       setState(() {
//         _currentIndex += isRight ? 1 : -1;
//         _dragOffset = 0.0;
//         _animationController.reset();
//         _offsetAnimation = Tween<Offset>(
//           begin: Offset.zero,
//           end: Offset.zero,
//         ).animate(_animationController);
//       });
//       _sideCardsController.forward(from: 0);
//     });
//   }

//   // ══════════════════════════════════════════════════════════════════════════
//   // ✅ ВЗАИМОДЕЙСТВИЕ
//   // ══════════════════════════════════════════════════════════════════════════

//   void _onCardTap(CountryModel country) {
//     DateSelectionDialog.show(
//       context,
//       country: country,
//       isDarkMode: widget.isDarkMode, // ✅ ПЕРЕДАЁМ
//       onDatesSelected: (startDate, endDate) {
//         debugPrint('📅 ${country.name}: $startDate → $endDate');
//         // TODO: Переход на экран поиска отелей
//       },
//     );
//   }

//   // ══════════════════════════════════════════════════════════════════════════
//   // ✅ РАСЧЁТЫ АНИМАЦИИ
//   // ══════════════════════════════════════════════════════════════════════════

//   double _calculateSwipeProgress(double screenWidth) {
//     final rawProgress =
//         (_dragOffset.abs() / (screenWidth * 0.8)).clamp(0.0, 1.0);
//     final firstEase = Curves.easeOut.transform(rawProgress);
//     return Curves.easeOutQuart.transform(firstEase);
//   }

//   double _calculateCardScale(double swipeProgress) {
//     const baseScale = 0.88;
//     const targetScale = 1.0;
//     return baseScale + (targetScale - baseScale) * swipeProgress;
//   }

//   double _calculateVerticalOffset(double swipeProgress) {
//     const baseVerticalOffset = 30.0;
//     return baseVerticalOffset * (1.0 - swipeProgress);
//   }

//   double _calculateHorizontalOffset(double swipeProgress) {
//     const baseEdgeOffset = 50.0;
//     return baseEdgeOffset * (1.0 - swipeProgress);
//   }

//   // ══════════════════════════════════════════════════════════════════════════
//   // ✅ BUILD
//   // ══════════════════════════════════════════════════════════════════════════

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return _buildLoadingState();
//     }

//     if (_countries.isEmpty) {
//       return _buildEmptyState();
//     }

//     final screenWidth = MediaQuery.of(context).size.width;
//     final cardWidth = screenWidth * _cardWidthRatio;

//     return Container(
//       height: _cardHeight,
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Stack(
//         clipBehavior: Clip.none,
//         alignment: Alignment.center,
//         children: [
//           ..._buildBackgroundCards(screenWidth, cardWidth),
//           _buildMainCard(screenWidth, cardWidth),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadingState() {
//     return Container(
//       height: _cardHeight,
//       alignment: Alignment.center,
//       child: const CircularProgressIndicator(
//         color: AppColors.primary,
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Container(
//       height: _cardHeight,
//       alignment: Alignment.center,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.public_off,
//             size: 64,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No countries found',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[700],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ══════════════════════════════════════════════════════════════════════════
//   // ✅ КАРТОЧКИ
//   // ══════════════════════════════════════════════════════════════════════════

//   List<Widget> _buildBackgroundCards(double screenWidth, double cardWidth) {
//     final isSwipingRight = _dragOffset > 0;
//     final isSwipingLeft = _dragOffset < 0;

//     return [
//       if (isSwipingRight)
//         _buildStackedCard(
//           (_currentIndex - 1) % _countries.length,
//           position: -1,
//           screenWidth: screenWidth,
//           cardWidth: cardWidth,
//         ),
//       if (isSwipingLeft)
//         _buildStackedCard(
//           (_currentIndex + 1) % _countries.length,
//           position: 1,
//           screenWidth: screenWidth,
//           cardWidth: cardWidth,
//         ),
//       if (isSwipingLeft)
//         _buildStackedCard(
//           (_currentIndex - 1) % _countries.length,
//           position: -1,
//           screenWidth: screenWidth,
//           cardWidth: cardWidth,
//         ),
//       if (isSwipingRight)
//         _buildStackedCard(
//           (_currentIndex + 1) % _countries.length,
//           position: 1,
//           screenWidth: screenWidth,
//           cardWidth: cardWidth,
//         ),
//       if (_dragOffset == 0.0) ...[
//         _buildStackedCard(
//           (_currentIndex - 1) % _countries.length,
//           position: -1,
//           screenWidth: screenWidth,
//           cardWidth: cardWidth,
//         ),
//         _buildStackedCard(
//           (_currentIndex + 1) % _countries.length,
//           position: 1,
//           screenWidth: screenWidth,
//           cardWidth: cardWidth,
//         ),
//       ],
//     ];
//   }

//   Widget _buildMainCard(double screenWidth, double cardWidth) {
//     final currentCountry = _countries[_currentIndex % _countries.length];

//     return GestureDetector(
//       onTap: () {
//         if (_dragOffset.abs() < 5) {
//           _onCardTap(currentCountry);
//         }
//       },
//       onPanUpdate: _onPanUpdate,
//       onPanEnd: (details) => _onPanEnd(details, screenWidth),
//       child: AnimatedBuilder(
//         animation: _animationController,
//         builder: (context, child) {
//           return Transform.translate(
//             offset: _offsetAnimation.value,
//             child: Transform.rotate(
//               angle: _offsetAnimation.value.dx / 1000,
//               child: child,
//             ),
//           );
//         },
//         child: SizedBox(
//           width: cardWidth,
//           height: _cardHeight,
//           child: _buildCountryCard(currentCountry),
//         ),
//       ),
//     );
//   }

//   Widget _buildStackedCard(
//     int index, {
//     required int position,
//     required double screenWidth,
//     required double cardWidth,
//   }) {
//     final country = _countries[index];
//     final swipeProgress = _calculateSwipeProgress(screenWidth);
//     final cardScale = _calculateCardScale(swipeProgress);
//     final verticalOffset = _calculateVerticalOffset(swipeProgress);
//     final horizontalOffset = _calculateHorizontalOffset(swipeProgress);

//     return AnimatedBuilder(
//       animation: _sideCardsAnimation,
//       builder: (context, child) {
//         final appearProgress = _sideCardsAnimation.value;
//         final finalScale = cardScale * (0.7 + 0.3 * appearProgress);

//         return Positioned(
//           top: verticalOffset,
//           left: position == -1 ? horizontalOffset : null,
//           right: position == 1 ? horizontalOffset : null,
//           child: Opacity(
//             opacity: appearProgress,
//             child: Transform.scale(
//               scale: finalScale,
//               alignment: Alignment.topCenter,
//               child: SizedBox(
//                 width: cardWidth,
//                 height: _cardHeight,
//                 child: _buildCountryCard(country),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // ══════════════════════════════════════════════════════════════════════════
//   // ✅ UI КОМПОНЕНТЫ
//   // ══════════════════════════════════════════════════════════════════════════

//   Widget _buildCountryCard(CountryModel country) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(28),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.25),
//             blurRadius: 30,
//             offset: const Offset(0, 15),
//             spreadRadius: -5,
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(28),
//         child: Stack(
//           children: [
//             _buildCardImage(country.imageUrl ?? ''),
//             _buildCardGradient(),
//             _buildPopularBadge(),
//             _buildFavoriteButton(),
//             _buildCardInfo(country),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCardImage(String imageUrl) {
//     return Positioned.fill(
//       child: Image.network(
//         imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/800',
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) => Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [AppColors.primary, AppColors.secondary],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCardGradient() {
//     return Positioned.fill(
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.transparent,
//               Colors.black.withOpacity(0.7),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPopularBadge() {
//     return Positioned(
//       top: 20,
//       left: 20,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//         decoration: BoxDecoration(
//           color: AppColors.primary,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.primary.withOpacity(0.4),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: const Text(
//           'Popular Place',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 12,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFavoriteButton() {
//     return Positioned(
//       top: 20,
//       right: 20,
//       child: ClipOval(
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.15),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.favorite_border_rounded,
//               color: Colors.white,
//               size: 22,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCardInfo(CountryModel country) {
//     return Positioned(
//       bottom: 24,
//       left: 20,
//       right: 20,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(22),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//           child: Container(
//             padding: const EdgeInsets.all(18),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(22),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   children: [
//                     if (country.flagEmoji != null) ...[
//                       Text(
//                         country.flagEmoji!,
//                         style: const TextStyle(fontSize: 24),
//                       ),
//                       const SizedBox(width: 8),
//                     ],
//                     Expanded(
//                       child: Text(
//                         country.name,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: -0.5,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     Flexible(child: _buildLocationChip(country.continent)),
//                     const SizedBox(width: 8),
//                     _buildRatingChip(country.rating),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLocationChip(String continent) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.12),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.location_on, color: Colors.white, size: 14),
//               const SizedBox(width: 4),
//               Flexible(
//                 child: Text(
//                   continent,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                   maxLines: 1,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRatingChip(double rating) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.12),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.star, color: Colors.amber, size: 14),
//               const SizedBox(width: 4),
//               Text(
//                 rating.toStringAsFixed(1),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
