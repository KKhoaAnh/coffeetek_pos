import '../models/product.dart';
import '../repositories/product_repository.dart';

class GetProductDetailUseCase {
  final ProductRepository repository;

  GetProductDetailUseCase(this.repository);

  Future<Product> execute(String id) async {
    return await repository.getProductById(id);
  }
}