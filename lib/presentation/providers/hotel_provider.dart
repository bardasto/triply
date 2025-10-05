import 'package:flutter/material.dart';
import '../../data/models/hotel_model.dart';
import '../../data/repositories/hotel_repository.dart';

class HotelProvider with ChangeNotifier {
  List<Hotel> _hotels = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 0;
  bool _hasMoreData = true;
  static const int _pageSize = 30; // Увеличили размер страницы

  List<Hotel> get hotels => _hotels;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;
  bool get hasHotels => _hotels.isNotEmpty;
  int get totalHotels => _hotels.length;

  // ✅ Загрузка первых отелей
  Future<void> loadInitialHotels() async {
    if (_isLoading) return;

    print('🏨 HotelProvider: Loading initial hotels...');
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _hasMoreData = true;
    notifyListeners();

    try {
      final newHotels = await HotelRepository.getHotelsPage(
        page: _currentPage,
        pageSize: _pageSize,
        refresh: true,
      );

      _hotels = newHotels;
      _hasMoreData = newHotels.length >= _pageSize;
      print('✅ HotelProvider: Loaded ${_hotels.length} initial hotels');
    } catch (e) {
      _error = e.toString();
      print('❌ HotelProvider: Error loading initial hotels: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🚀 УЛУЧШЕННАЯ загрузка дополнительных отелей
  Future<void> loadMoreHotels() async {
    if (_isLoadingMore || !_hasMoreData || _error != null) {
      print(
          '🚫 Cannot load more: loading=${_isLoadingMore}, hasMore=${_hasMoreData}, error=${_error != null}');
      return;
    }

    print(
        '📄 HotelProvider: Loading more hotels (page ${_currentPage + 1})...');
    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final newHotels = await HotelRepository.getHotelsPage(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (newHotels.isNotEmpty) {
        _hotels.addAll(newHotels);
        _hasMoreData = newHotels.length >= _pageSize;
        print(
            '✅ HotelProvider: Added ${newHotels.length} more hotels. Total: ${_hotels.length}');
        print('📊 Has more data: $_hasMoreData');
      } else {
        _hasMoreData = false;
        print('🏁 HotelProvider: No more hotels to load');
      }
    } catch (e) {
      _error = e.toString();
      print('❌ HotelProvider: Error loading more hotels: $e');
      _currentPage--; // Откатываем страницу при ошибке
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ✅ Рефреш всех отелей
  Future<void> refreshHotels() async {
    print('🔄 HotelProvider: Refreshing all hotels...');
    HotelRepository.clearCache();
    _hotels.clear();
    _error = null;
    _hasMoreData = true;
    _currentPage = 0;
    notifyListeners();
    await loadInitialHotels();
  }

  // ✅ Поиск отелей по городу
  Future<void> searchHotelsByCity(String cityCode) async {
    print('🔍 HotelProvider: Searching hotels in $cityCode...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final searchResults = await HotelRepository.searchHotelsByCity(cityCode);
      _hotels = searchResults;
      _hasMoreData = false; // Для поиска отключаем пагинацию
      _currentPage = 0;
      print('✅ HotelProvider: Found ${_hotels.length} hotels in $cityCode');
    } catch (e) {
      _error = e.toString();
      print('❌ HotelProvider: Error searching hotels: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearHotels() {
    _hotels.clear();
    _currentPage = 0;
    _hasMoreData = true;
    _error = null;
    notifyListeners();
  }
}
