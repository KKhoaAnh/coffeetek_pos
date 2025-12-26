import 'package:flutter/material.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/category.dart';
import '../../../domain/usecases/get_products_usecase.dart';

class PosViewModel extends ChangeNotifier {
  final GetProductsUseCase _getProductsUseCase;

  List<Product> _allProducts = [];
  List<Category> _categories = [];
  
  String _selectedCategoryId = 'ALL';
  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedCategoryId => _selectedCategoryId;
  List<Category> get categories => _categories;

  List<Product> get filteredProducts {
    if (_selectedCategoryId == 'ALL') {
      return _allProducts;
    }
    return _allProducts.where((p) => p.categoryId == _selectedCategoryId).toList();
  }

  PosViewModel(this._getProductsUseCase);

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _allProducts = await _getProductsUseCase.execute();
      
      _allProducts = _allProducts.where((p) => p.isActive).toList();

      final Set<String> categoryIds = {};
      
      List<Category> dynamicCategories = [
        Category(id: 'ALL', name: 'Tất cả', imageUrl: null)
      ];

      for (var product in _allProducts) {
              if (!categoryIds.contains(product.categoryId)) {
                categoryIds.add(product.categoryId);
                
                dynamicCategories.add(Category(
                  id: product.categoryId, 
                  name: product.categoryName,
                  imageUrl: product.categoryImage,
                  gridCount: product.gridCount ?? 4,
                ));
              }
            }
            _categories = dynamicCategories;

    } catch (e) {
      _errorMessage = "Không thể tải menu: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }
}