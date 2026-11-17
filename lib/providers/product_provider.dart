import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  static const int pageSize = 8; // 6-8 allowed

  List<Product> products = [];
  bool isLoading = false;
  String? error;

  // Pagination
  int currentPage = 0; // zero-based
  int totalCount = 0;

  // Price filter
  double minPrice = 0;
  double maxPrice = 1000;
  RangeValues selectedRange = const RangeValues(0, 1000); // applied to query
  RangeValues previewRange = const RangeValues(0, 1000); // while dragging

  int get totalPages => totalCount == 0 ? 1 : (totalCount / pageSize).ceil();
  bool get hasNext => currentPage < totalPages - 1;
  bool get hasPrev => currentPage > 0;

  /// Call once when the shop page opens.
  Future<void> init() async {
    await _loadPriceBounds();
    await fetchProducts();
  }

  Future<void> _loadPriceBounds() async {
    try {
      final low = await _client
          .from('products')
          .select('price')
          .order('price', ascending: true)
          .limit(1)
          .maybeSingle();
      final high = await _client
          .from('products')
          .select('price')
          .order('price', ascending: false)
          .limit(1)
          .maybeSingle();

      if (low != null && high != null) {
        minPrice = (low['price'] as num).toDouble().floorToDouble();
        maxPrice = (high['price'] as num).toDouble().ceilToDouble();
        if (maxPrice <= minPrice) maxPrice = minPrice + 1;
        selectedRange = RangeValues(minPrice, maxPrice);
        previewRange = selectedRange;
      }
    } catch (e) {
      error = e.toString();
    }
  }

  /// Supabase query with price filter + pagination (range).
  Future<void> fetchProducts() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final from = currentPage * pageSize;
      final to = from + pageSize - 1;

      final response = await _client
          .from('products')
          .select()
          .gte('price', selectedRange.start)
          .lte('price', selectedRange.end)
          .order('id', ascending: true)
          .range(from, to)
          .count(CountOption.exact);

      products = (response.data as List)
          .map((e) => Product.fromMap(e as Map<String, dynamic>))
          .toList();
      totalCount = response.count;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Slider dragging (UI only, no query yet)
  void updatePreview(RangeValues values) {
    previewRange = values;
    notifyListeners();
  }

  // Slider released: apply filter, go back to page 1
  Future<void> applyPriceFilter(RangeValues values) async {
    selectedRange = values;
    previewRange = values;
    currentPage = 0;
    await fetchProducts();
  }

  Future<void> nextPage() async {
    if (!hasNext) return;
    currentPage++;
    await fetchProducts();
  }

  Future<void> prevPage() async {
    if (!hasPrev) return;
    currentPage--;
    await fetchProducts();
  }
}
