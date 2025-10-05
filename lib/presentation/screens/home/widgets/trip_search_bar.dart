import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';

class TripSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onTap;

  const TripSearchBar({
    Key? key,
    required this.onSearch,
    required this.onTap,
  }) : super(key: key);

  @override
  State<TripSearchBar> createState() => _TripSearchBarState();
}

class _TripSearchBarState extends State<TripSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // ✅ Увеличили vertical margin
      // ✅ ДОБАВЛЯЕМ ОБЪЕМНОСТЬ
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // Основная тень
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          // Верхняя подсветка для объема
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 56, // ✅ УВЕЛИЧИЛИ ВЫСОТУ ПОЛЯ ВВОДА
          decoration: BoxDecoration(
            // ✅ ГРАДИЕНТНЫЙ ФОН ДЛЯ ОБЪЕМА
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // ✅ ОБЪЕМНАЯ ИКОНКА ПОИСКА
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16), // ✅ Увеличили отступ
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200]!.withOpacity(0.5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ),

              // Search field
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Where would you like to go?',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 16, // ✅ Увеличили шрифт
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: widget.onSearch,
                  style: TextStyle(
                    fontSize: 16, // ✅ Увеличили шрифт
                    color: AppColors.text,
                  ),
                ),
              ),

              // ✅ ОБЪЕМНАЯ КНОПКА МИКРОФОНА
              GestureDetector(
                onTap: () {
                  print('🎤 Voice search tapped');
                  // TODO: Интеграция с голосовым поиском
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12), // ✅ Увеличили отступ
                  padding: const EdgeInsets.all(10), // ✅ Увеличили padding
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    // ✅ ОБЪЕМНЫЕ ТЕНИ
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 2,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
