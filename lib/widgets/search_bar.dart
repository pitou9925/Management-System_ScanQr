import 'package:flutter/material.dart';
import '../models/product.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController searchController;
  final SearchFilter selectedFilter;
  final String selectedCategory;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final List<Product> products;
  final Function(SearchFilter) onFilterChanged;
  final Function(String) onCategoryChanged;
  final Function(int, int) onQuantityRangeChanged;
  final VoidCallback onApplyFilters;

  const SearchBarWidget({
    super.key,
    required this.searchController,
    required this.selectedFilter,
    required this.selectedCategory,
    required this.minPriceController,
    required this.maxPriceController,
    required this.products,
    required this.onFilterChanged,
    required this.onCategoryChanged,
    required this.onQuantityRangeChanged,
    required this.onApplyFilters,
  });

  void _showAdvancedSearchDialog(BuildContext context) {
    int _minQuantity = 0;
    int _maxQuantity = 1000;
    SearchFilter _tempFilter = selectedFilter;
    String _tempCategory = selectedCategory;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Advanced Search Options',
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Filter
                const Text('Search Filter:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<SearchFilter>(
                  value: _tempFilter,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: SearchFilter.values.map((filter) {
                    String displayName = filter.toString().split('.').last;
                    displayName = displayName.replaceAllMapped(
                      RegExp(r'([A-Z])'),
                          (match) => ' ${match.group(0)}',
                    ).trim();
                    displayName = displayName[0].toUpperCase() + displayName.substring(1);
                    return DropdownMenuItem(value: filter, child: Text(displayName));
                  }).toList(),
                  onChanged: (value) => setStateDialog(() => _tempFilter = value!),
                ),

                const SizedBox(height: 16),

                // Category Filter
                const Text('Category:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _tempCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['All Categories', ...products.map((p) => p.category).toSet()]
                      .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                      .toList(),
                  onChanged: (value) => setStateDialog(() => _tempCategory = value!),
                ),

                const SizedBox(height: 16),

                // Quantity Range
                const Text('Quantity Range:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _minQuantity.toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Min',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) => _minQuantity = int.tryParse(value) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _maxQuantity.toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Max',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) => _maxQuantity = int.tryParse(value) ?? 1000,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Price Range
                const Text('Price Range:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: minPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Min Price',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: maxPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Max Price',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                onFilterChanged(SearchFilter.all);
                onCategoryChanged('All Categories');
                minPriceController.clear();
                maxPriceController.clear();
                onQuantityRangeChanged(0, 1000);
                onApplyFilters();
                Navigator.pop(context);
              },
              child: const Text('Reset', style: TextStyle(color: Color(0xFF666666))),
            ),
            ElevatedButton(
              onPressed: () {
                onFilterChanged(_tempFilter);
                onCategoryChanged(_tempCategory);
                onQuantityRangeChanged(_minQuantity, _maxQuantity);
                onApplyFilters();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: const TextStyle(color: Color(0xFF999999)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF2196F3)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _showAdvancedSearchDialog(context),
                  icon: const Icon(Icons.tune, color: Colors.white),
                  tooltip: 'Advanced Search',
                ),
              ),
            ],
          ),

          // Quick Filter Chips
          if (selectedFilter != SearchFilter.all || selectedCategory != 'All Categories') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (selectedFilter != SearchFilter.all)
                    Chip(
                      label: Text(selectedFilter.toString().split('.').last),
                      onDeleted: () {
                        onFilterChanged(SearchFilter.all);
                      },
                      backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                      deleteIconColor: const Color(0xFF2196F3),
                    ),
                  if (selectedCategory != 'All Categories')
                    Chip(
                      label: Text('Category: $selectedCategory'),
                      onDeleted: () {
                        onCategoryChanged('All Categories');
                      },
                      backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                      deleteIconColor: const Color(0xFF4CAF50),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}