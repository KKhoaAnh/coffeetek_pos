import '../models/product.dart';
import '../models/modifier/modifier_group.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  
  Future<Product> getProductById(String id);

  Future<List<ModifierGroup>> getProductModifiers(String productId);
}