import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/search_bar.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProductInventoryScreen extends StatefulWidget {
  const ProductInventoryScreen({super.key});

  @override
  State<ProductInventoryScreen> createState() => _ProductInventoryScreenState();
}

class _ProductInventoryScreenState extends State<ProductInventoryScreen> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  SearchFilter _selectedFilter = SearchFilter.all;
  String _selectedCategory = 'All Categories';
  int _minQuantity = 0;
  int _maxQuantity = 1000;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsJson = prefs.getString('products');
    if (productsJson != null) {
      final List<dynamic> jsonList = jsonDecode(productsJson);
      setState(() {
        products = jsonList.map((json) => Product.fromJson(json)).toList();
        filteredProducts = products;
      });
    }
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', jsonEncode(products.map((p) => p.toJson()).toList()));
  }

  void _filterProducts() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      List<Product> filtered = products;

      if (query.isNotEmpty) {
        switch (_selectedFilter) {
          case SearchFilter.name:
            filtered = filtered.where((product) => product.name.toLowerCase().contains(query)).toList();
            break;
          case SearchFilter.category:
            filtered = filtered.where((product) => product.category.toLowerCase().contains(query)).toList();
            break;
          case SearchFilter.barcode:
            filtered = filtered.where((product) => product.barcode.toLowerCase().contains(query)).toList();
            break;
          case SearchFilter.all:
          default:
            filtered = filtered.where((product) =>
            product.name.toLowerCase().contains(query) ||
                product.category.toLowerCase().contains(query) ||
                product.barcode.toLowerCase().contains(query)).toList();
        }
      }

      switch (_selectedFilter) {
        case SearchFilter.lowStock:
          filtered = filtered.where((product) => product.quantity <= 5).toList();
          break;
        case SearchFilter.highStock:
          filtered = filtered.where((product) => product.quantity > 20).toList();
          break;
        case SearchFilter.recentlyAdded:
          final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
          filtered = filtered.where((product) => product.createdAt.isAfter(threeDaysAgo)).toList();
          break;
        case SearchFilter.recentlyUpdated:
          final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
          filtered = filtered.where((product) => product.updatedAt.isAfter(threeDaysAgo)).toList();
          break;
        default:
          break;
      }

      if (_selectedCategory != 'All Categories') {
        filtered = filtered.where((product) => product.category == _selectedCategory).toList();
      }

      filtered = filtered.where((product) =>
      product.quantity >= _minQuantity && product.quantity <= _maxQuantity).toList();

      final minPrice = double.tryParse(_minPriceController.text) ?? 0.0;
      final maxPrice = double.tryParse(_maxPriceController.text) ?? double.infinity;
      filtered = filtered.where((product) => product.price >= minPrice && product.price <= maxPrice).toList();

      filteredProducts = filtered;
    });
  }

  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Confirm Delete',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Delete ${filteredProducts[index].name}?',
          style: const TextStyle(color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF666666))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                products.remove(filteredProducts[index]);
                filteredProducts = products;
                _saveProducts();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product deleted', style: TextStyle(color: Colors.white)),
                  backgroundColor: Color(0xFF2196F3),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(Product product) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product.name);
    final categoryController = TextEditingController(text: product.category);
    final quantityController = TextEditingController(text: product.quantity.toString());
    final priceController = TextEditingController(text: product.price.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Edit Product',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameController, 'Name', 'Name is required'),
                const SizedBox(height: 16),
                _buildTextField(categoryController, 'Category', 'Category is required'),
                const SizedBox(height: 16),
                _buildTextField(
                  quantityController,
                  'Quantity',
                  'Quantity is required',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Quantity is required';
                    if (int.tryParse(value) == null || int.parse(value) < 0) return 'Enter a valid quantity';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  priceController,
                  'Price',
                  'Price is required',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value!.isEmpty) return 'Price is required';
                    if (double.tryParse(value) == null || double.parse(value) < 0) return 'Enter a valid price';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF666666))),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  final index = products.indexWhere((p) => p.barcode == product.barcode);
                  if (index != -1) {
                    products[index].name = nameController.text;
                    products[index].category = categoryController.text;
                    products[index].updateQuantity(int.parse(quantityController.text));
                    products[index].price = double.parse(priceController.text);
                  }
                  filteredProducts = products;
                  _saveProducts();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product updated', style: TextStyle(color: Colors.white)),
                    backgroundColor: Color(0xFF2196F3),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      String errorMessage, {
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF666666)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator ?? (value) => value!.isEmpty ? errorMessage : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Inventory',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProducts();
          setState(() {});
        },
        color: const Color(0xFF2196F3),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchBarWidget(
                  searchController: _searchController,
                  selectedFilter: _selectedFilter,
                  selectedCategory: _selectedCategory,
                  minPriceController: _minPriceController,
                  maxPriceController: _maxPriceController,
                  products: products,
                  onFilterChanged: (filter) {
                    setState(() => _selectedFilter = filter);
                    _filterProducts();
                  },
                  onCategoryChanged: (category) {
                    setState(() => _selectedCategory = category);
                    _filterProducts();
                  },
                  onQuantityRangeChanged: (min, max) {
                    setState(() {
                      _minQuantity = min;
                      _maxQuantity = max;
                    });
                    _filterProducts();
                  },
                  onApplyFilters: _filterProducts,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Products (${filteredProducts.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (filteredProducts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'Try adjusting your search filters'
                              : 'No products available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final isLowStock = product.quantity <= 5;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isLowStock
                              ? Border.all(color: const Color(0xFFFF9800), width: 1)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isLowStock
                                  ? const Color(0xFFFF9800).withOpacity(0.1)
                                  : const Color(0xFF2196F3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: isLowStock ? const Color(0xFFFF9800) : const Color(0xFF2196F3),
                              size: 24,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.name.isNotEmpty ? product.name : 'Unnamed Product',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isLowStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9800),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'LOW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category: ${product.category.isNotEmpty ? product.category : 'N/A'}',
                                  style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Qty: ${product.quantity}',
                                        style: TextStyle(
                                          color: isLowStock ? const Color(0xFFFF9800) : const Color(0xFF666666),
                                          fontSize: 13,
                                          fontWeight: isLowStock ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '\$${product.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF2196F3),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Updated: ${product.updatedAt.toString().split(' ')[0]}',
                                  style: const TextStyle(color: Color(0xFF999999), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
                            onPressed: () => _deleteProduct(index),
                          ),
                          onTap: () => _showProductDialog(product),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
}