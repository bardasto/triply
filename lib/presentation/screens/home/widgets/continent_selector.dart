// import 'dart:ui';
// import 'package:flutter/material.dart';

// class ContinentSelector extends StatelessWidget {
//   final String selectedContinent;
//   final Function(String) onContinentSelected;

//   const ContinentSelector({
//     Key? key,
//     required this.selectedContinent,
//     required this.onContinentSelected,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final continents = ['Africa', 'Europe', 'Asia', 'America', 'Oceania'];

//     return SizedBox(
//       height: 36,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         padding:
//             const EdgeInsets.symmetric(horizontal: 20), // ✅ Отступы от краев
//         itemCount: continents.length,
//         itemBuilder: (context, index) {
//           final continent = continents[index];
//           final isSelected = continent == selectedContinent;

//           return Padding(
//             padding:
//                 const EdgeInsets.only(right: 15), // ✅ Отступ между кнопками
//             child: GestureDetector(
//               onTap: () => onContinentSelected(continent),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(22),
//                 child: BackdropFilter(
//                   filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//                   child: Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                         colors: isSelected
//                             ? [
//                                 Colors.white.withOpacity(0.3),
//                                 Colors.white.withOpacity(0.2),
//                               ]
//                             : [
//                                 const Color(0xFF1F2123).withOpacity(0.5),
//                                 const Color(0xFF1F2123).withOpacity(0.3),
//                               ],
//                       ),
//                       borderRadius: BorderRadius.circular(18),
//                     ),
//                     child: Center(
//                       child: Text(
//                         continent,
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 13,
//                           fontWeight:
//                               isSelected ? FontWeight.w600 : FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
