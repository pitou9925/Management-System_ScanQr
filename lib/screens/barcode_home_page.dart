import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback

import 'package:managment_scanbr/screens/productInventor_screen.dart';import 'package:managment_scanbr/screens/stock_out_today_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import '../models/product.dart'; // Ensure this path is correct
import '../models/transaction.dart'; // NEW: Import Transaction model
import '../widgets/stat_card.dart'; // Ensure this path is correct
import '../widgets/action_button.dart'; // Ensure this path is correct
import 'custom_scanner_screen.dart'; // IMPORT YOUR NEW CUSTOM SCANNER SCREEN
import 'low_stock_screen.dart'; // IMPORT THE NEW LOW STOCK SCREEN
import 'stock_in_today_screen.dart'; // IMPORT THE NEW STOCK IN TODAY SCREEN

// Enum for search filters (you might define this in a separate file or directly here)
enum SearchFilter {
  all,
  name,
  category,
  barcode,
  lowStock,
  highStock,
  recentlyAdded,
  recentlyUpdated,
}

class BarcodeHomePage extends StatefulWidget {
  const BarcodeHomePage({super.key});

  @override
  State<BarcodeHomePage> createState() => _BarcodeHomePageState();
}

class _BarcodeHomePageState extends State<BarcodeHomePage> with SingleTickerProviderStateMixin {
  List<Product> products = [];
  List<Transaction> transactions = []; // NEW: State variable for transactions
  String scanResult = 'No barcode scanned yet';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  List<Product> filteredProducts = [];
  bool exportLowStockOnly = false;
  int _stockInToday = 0;
  int _stockOutToday = 0;
  // This key changes daily, ensuring stock counts reset automatically.
  String _todayKey = DateTime.now().toIso8601String().split('T')[0];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  SearchFilter _selectedFilter = SearchFilter.all; // Default filter
  String _selectedCategory = 'All Categories'; // Default category
  int _minQuantity = 0; // Default min quantity
  int _maxQuantity = 1000; // Default max quantity

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadTransactions(); // NEW: Load transactions on init
    _loadStockToday();
    // This listener is for the search bar, make sure it's actually used in your UI.
    _searchController.addListener(_filterProducts);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward(); // Start fade-in animation
  }

  // Helper method to get greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning! 🌅";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon! ☀️";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening! 🌆";
    } else {
      return "Good Night! 🌙";
    }
  }

  // Helper method to get greeting icon
  String _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "🌅";
    } else if (hour >= 12 && hour < 17) {
      return "☀️";
    } else if (hour >= 17 && hour < 21) {
      return "🌆";
    } else {
      return "🌙";
    }
  }

  // Helper method to get current date and time
  String _getCurrentDateTime() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    final day = now.day;
    final year = now.year;

    return '$weekday, $month $day, $year';
  }

  // Load products from SharedPreferences
  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsJson = prefs.getString('products');
    if (productsJson != null) {
      final List<dynamic> jsonList = jsonDecode(productsJson);
      setState(() {
        products = jsonList.map((json) => Product.fromJson(json)).toList();
        filteredProducts = products; // Initialize filtered products
      });
    }
  }

  // Save products to SharedPreferences
  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', jsonEncode(products.map((p) => p.toJson()).toList()));
  }

  // NEW: Load transactions from SharedPreferences
  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsJson = prefs.getString('transactions');
    if (transactionsJson != null) {
      final List<dynamic> jsonList = jsonDecode(transactionsJson);
      setState(() {
        transactions = jsonList.map((json) => Transaction.fromJson(json)).toList();
      });
    }
  }

  // NEW: Save transactions to SharedPreferences
  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('transactions', jsonEncode(transactions.map((t) => t.toJson()).toList()));
  }

  // Load today's stock in/out from SharedPreferences
  // This handles the daily reset by looking for a key specific to the current date.
  Future<void> _loadStockToday() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stockInToday = prefs.getInt('stock_in_$_todayKey') ?? 0;
      _stockOutToday = prefs.getInt('stock_out_$_todayKey') ?? 0;
    });
  }

  // Save today's stock in/out to SharedPreferences
  Future<void> _saveStockToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stock_in_$_todayKey', _stockInToday);
    await prefs.setInt('stock_out_$_todayKey', _stockOutToday);
  }

  // Filter products based on search query, selected filter, category, quantity, and price
  void _filterProducts() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      List<Product> filtered = products;

      // Apply text search filter
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

      // Apply specific filter types
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

      // Apply category filter
      if (_selectedCategory != 'All Categories') {
        filtered = filtered.where((product) => product.category == _selectedCategory).toList();
      }

      // Apply quantity range filter
      filtered = filtered.where((product) =>
      product.quantity >= _minQuantity && product.quantity <= _maxQuantity).toList();

      // Apply price range filter
      final minPrice = double.tryParse(_minPriceController.text) ?? 0.0;
      final maxPrice = double.tryParse(_maxPriceController.text) ?? double.infinity;
      filtered = filtered.where((product) => product.price >= minPrice && product.price <= maxPrice).toList();

      filteredProducts = filtered;
    });
  }

  // Request camera permission (called before navigating to scanner screen)
  Future<bool> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  // Request storage permission for PDF export
  Future<bool> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  // Unified barcode scan handler for Stock In and Stock Out
  Future<void> _handleBarcodeScan({required bool isStockIn}) async {
    bool hasPermission = await _requestCameraPermission();
    if (!hasPermission) {
      _showSnackBar('Camera permission denied. Please enable in app settings.');
      return;
    }

    final String? scannedValue = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomScannerScreen()),
    );

    if (scannedValue != null && scannedValue.isNotEmpty) {
      final existingProductIndex = products.indexWhere(
            (product) => product.barcode == scannedValue,
      );

      Product? productToUpdate;
      if (existingProductIndex != -1) {
        productToUpdate = products[existingProductIndex];
      }

      if (productToUpdate == null || productToUpdate.name.isEmpty) {
        _showProductDialog(scannedValue);
      } else {
        _showStockDialog(productToUpdate, isStockIn: isStockIn);
      }
    } else {
      _showSnackBar('Scan cancelled or no barcode found.');
    }
  }


  // Export product data to PDF (MODIFIED FOR TABULAR LAYOUT AND TOTAL SUMMARY)
  Future<void> _exportToPDF() async {
    try {
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        _showSnackBar('Storage permission denied. Cannot export PDF.');
        return;
      }

      _showSnackBar('Generating PDF report...'); // Provide immediate feedback

      final pdfDoc = pw.Document();
      final exportProducts = exportLowStockOnly ? products.where((p) => p.quantity <= 5).toList() : products;

      // Calculate total summary price
      double totalSummaryPrice = 0.0;
      for (var product in exportProducts) {
        totalSummaryPrice += (product.quantity * product.price);
      }

      pdfDoc.addPage(
        pw.MultiPage(
          pageFormat: pdf.PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Product Inventory Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 16),
            if (exportProducts.isEmpty)
              pw.Center(
                child: pw.Text('No products to export based on current filters.',
                    style: const pw.TextStyle(fontSize: 14)),
              )
            else
              pw.Table.fromTextArray(
                headers: ['Barcode', 'Name', 'Category', 'Quantity', 'Price', 'Added On', 'Updated On'],
                data: exportProducts.map((product) => [
                  product.barcode,
                  product.name,
                  product.category,
                  product.quantity.toString(),
                  '\$${product.price.toStringAsFixed(2)}',
                  product.createdAt.toIso8601String().split('T')[0], // Format date
                  product.updatedAt.toIso8601String().split('T')[0], // Format date
                ]).toList(),
                border: pw.TableBorder.all(color: pdf.PdfColors.grey400, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: pdf.PdfColors.blueGrey800),
                headerDecoration: const pw.BoxDecoration(color: pdf.PdfColors.blueGrey100),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.all(6),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2), // Barcode
                  1: const pw.FlexColumnWidth(3), // Name
                  2: const pw.FlexColumnWidth(2), // Category
                  3: const pw.FlexColumnWidth(1), // Quantity
                  4: const pw.FlexColumnWidth(1.5), // Price
                  5: const pw.FlexColumnWidth(2), // Added On
                  6: const pw.FlexColumnWidth(2), // Updated On
                },
              ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total Inventory Value: \$${totalSummaryPrice.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: pdf.PdfColors.blueGrey800,
                ),
              ),
            ),
          ],
        ),
      );

      final directory = await getApplicationDocumentsDirectory(); // Or getExternalStorageDirectory() for more public access
      String formattedDate = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final path = '${directory.path}/products_report_$formattedDate.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdfDoc.save());
      await OpenFile.open(path);

      _showSnackBar('PDF report exported to $path');
    } catch (e) {
      _showSnackBar('Error exporting PDF: $e');
    }
  }

  // Show dialog to add/edit product details
  void _showProductDialog(String barcode, [Product? existingProduct]) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingProduct?.name ?? '');
    final categoryController = TextEditingController(text: existingProduct?.category ?? '');
    final quantityController = TextEditingController(text: existingProduct?.quantity.toString() ?? '0');
    final priceController = TextEditingController(text: existingProduct?.price.toString() ?? '0.0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          existingProduct == null ? 'Add New Product' : 'Edit Product',
          style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
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
                  if (existingProduct == null) {
                    // Add new product
                    final product = Product(
                      barcode: barcode,
                      name: nameController.text,
                      category: categoryController.text,
                      quantity: int.parse(quantityController.text),
                      price: double.parse(priceController.text),
                    );
                    products.add(product);

                    // NEW: Log the initial stock-in as a transaction
                    transactions.add(Transaction(
                      productBarcode: product.barcode,
                      quantity: product.quantity,
                      timestamp: DateTime.now(),
                      transactionType: 'stock_in',
                    ));

                  } else {
                    // Update existing product
                    final index = products.indexWhere((p) => p.barcode == existingProduct.barcode);
                    if (index != -1) {
                      products[index].name = nameController.text;
                      products[index].category = categoryController.text;
                      // Note: updateQuantity also sets updatedAt
                      products[index].updateQuantity(int.parse(quantityController.text));
                      products[index].price = double.parse(priceController.text);
                    }
                  }
                  _saveProducts(); // Save changes
                  _saveTransactions(); // NEW: Save transactions
                  _filterProducts(); // Re-filter to update UI
                  scanResult = 'Product ${existingProduct == null ? "added" : "updated"}: ${nameController.text}';
                });
                Navigator.pop(context);
                _showSnackBar('Product ${existingProduct == null ? "added" : "updated"} successfully!');
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

  // Helper widget for consistent text fields
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

  // Show dialog to update product stock (in/out)
  void _showStockDialog(Product product, {bool? isStockIn}) {
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();
    bool stockIn = isStockIn ?? true; // Pre-select based on `isStockIn` parameter

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Update Stock: ${product.name}',
            style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display current quantity prominently
                Text(
                  'Current Quantity: ${product.quantity}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 16),
                // Only show radio buttons if `isStockIn` is not explicitly passed (e.g., from product inventory)
                if (isStockIn == null) ...[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Stock In', style: TextStyle(color: Color(0xFF1A1A1A))),
                          leading: Radio<bool>(
                            value: true,
                            groupValue: stockIn,
                            onChanged: (value) => setStateDialog(() => stockIn = value!),
                            activeColor: const Color(0xFF4CAF50),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Stock Out', style: TextStyle(color: Color(0xFF1A1A1A))),
                          leading: Radio<bool>(
                            value: false,
                            groupValue: stockIn,
                            onChanged: (value) => setStateDialog(() => stockIn = value!),
                            activeColor: const Color(0xFFFF9800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildTextField(
                  quantityController,
                  'Quantity to ${stockIn ? 'Add' : 'Remove'}',
                  'Quantity is required',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Quantity is required';
                    if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Enter a valid quantity (>0)';
                    return null;
                  },
                ),
              ],
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
                  final quantity = int.parse(quantityController.text);
                  setState(() {
                    final index = products.indexWhere((p) => p.barcode == product.barcode);
                    if (index != -1) {
                      int newQuantity = products[index].quantity + (stockIn ? quantity : -quantity);
                      if (newQuantity < 0) {
                        newQuantity = 0;
                        _showSnackBar('Cannot remove more than available stock. Quantity set to 0.');
                      }
                      products[index].updateQuantity(newQuantity); // This updates `updatedAt`
                    }

                    // NEW: Log the transaction
                    transactions.add(Transaction(
                      productBarcode: product.barcode,
                      quantity: quantity,
                      timestamp: DateTime.now(),
                      transactionType: stockIn ? 'stock_in' : 'stock_out',
                    ));

                    // Update daily stock in/out
                    if (stockIn) {
                      _stockInToday += quantity;
                    } else {
                      _stockOutToday += quantity;
                    }
                    _saveProducts(); // Save changes
                    _saveTransactions(); // NEW: Save transactions
                    _saveStockToday(); // Save daily stock counts
                    _filterProducts(); // Re-filter to update UI
                    scanResult = 'Stock ${stockIn ? "added" : "removed"}: ${product.name}';
                  });
                  Navigator.pop(context);
                  _showSnackBar('Stock updated for ${product.name}!');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // Clear all products confirmation dialog
  void _clearProducts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Confirm Clear All Products',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to delete all products? This action cannot be undone.',
          style: TextStyle(color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF666666))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                products.clear();
                transactions.clear(); // NEW: Clear transactions as well
                filteredProducts.clear(); // Clear filtered list as well
                scanResult = 'No barcode scanned yet';
                _saveProducts(); // Save empty list
                _saveTransactions(); // NEW: Save empty transactions list
              });
              Navigator.pop(context);
              _showSnackBar('All products cleared successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935), // Red color for destructive action
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  // Show a customizable SnackBar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF2196F3),
        behavior: SnackBarBehavior.floating, // Makes it appear above other content
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Helper getter for low stock products
  List<Product> get _lowStockProducts => products.where((p) => p.quantity <= 5).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Leading logo (left side)
        leading: Padding(
          padding: const EdgeInsets.only(left: 1.0), // Padding from the left edge
          child: Image.asset(
            'assets/images/centrepoint_healthcare_logo.png', // Main logo path
            height: 30, // Consistent height for both logos
            width: 30,  // Consistent width for both logos
          ),
        ),
        // Central Title
        title: const Text(
          'បន្ទប់ពិគ្រោះ និងព្យាបាលជំងឺ ទ័ពមានជ័យ', // Khmer text for "Tap Mean Chey Clinic"
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15), // Adjusted font size
          overflow: TextOverflow.ellipsis, // Truncate long text with "..."
        ),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        // Actions (widgets on the right side)
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 1.0), // Padding from the right edge
            child: Image.asset(
              'assets/images/centrepoint_healthcare_logo.png', // Second logo's actual path
              height: 30, // Consistent height for both logos
              width: 30,  // Consistent width for both logos
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadProducts(); // Reload products on pull-to-refresh
            await _loadTransactions(); // NEW: Reload transactions on pull-to-refresh
            await _loadStockToday(); // Reload today's stock counts
            setState(() {}); // Trigger a rebuild
          },
          color: const Color(0xFF2196F3),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Always allow scrolling even if content is small
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2196F3),
                          Color(0xFF1976D2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow( // Corrected syntax here
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getGreetingIcon(),
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                            children: [
                              const Text(
                                'Dr. Theara', // User's name
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 30,
                              ),
                            ]
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getCurrentDateTime(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stat Cards (Total Products & Low Stock)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProductInventoryScreen()),
                            ).then((_) {
                              // Reload products and stock when returning from inventory screen
                              _loadProducts();
                              _loadStockToday();
                              _loadTransactions(); // NEW: Reload transactions
                            });
                          },
                          child: StatCard(
                            title: 'Total Products',
                            value: '${products.length}',
                            icon: Icons.inventory_2_outlined,
                            color: const Color(0xFF2196F3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector( // Add GestureDetector here
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LowStockScreen(lowStockProducts: _lowStockProducts),
                              ),
                            ).then((_) {
                              // Reload products and stock when returning from low stock screen
                              _loadProducts();
                              _loadStockToday();
                              _loadTransactions(); // NEW: Reload transactions
                            });
                          },
                          child: StatCard(
                            title: 'Low Stock',
                            value: '${_lowStockProducts.length}',
                            icon: Icons.warning_amber_outlined,
                            color: const Color(0xFFFF9800), // Orange for warning
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stat Cards (Stock In Today & Stock Out Today)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector( // Added for navigation to Stock In Today screen
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StockInTodayScreen(
                                  products: products, // Pass the products list
                                  transactions: transactions, // Pass the transactions list
                                ),
                              ),
                            ).then((_) {
                              _loadProducts();
                              _loadStockToday();
                              _loadTransactions(); // NEW: Reload transactions
                            });
                          },
                          child: StatCard(
                            title: 'Stock In Today',
                            value: '$_stockInToday',
                            icon: Icons.trending_up,
                            color: const Color(0xFF4CAF50), // Green for positive
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector( // ADD THIS GestureDetector for Stock Out Today
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StockOutTodayScreen(
                                  products: products, // Pass the products list
                                  transactions: transactions, // Pass the transactions list
                                ),
                              ),
                            ).then((_) {
                              // Reload products and stock when returning from Stock Out Today screen
                              _loadProducts();
                              _loadStockToday();
                              _loadTransactions(); // NEW: Reload transactions
                            });
                          },
                          child: StatCard(
                            title: 'Stock Out Today',
                            value: '$_stockOutToday',
                            icon: Icons.trending_down,
                            color: const Color(0xFFF44336), // Red for negative
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          title: 'Stock In',
                          icon: Icons.qr_code_2,
                          color: const Color(0xFF4CAF50),
                          onTap: () => _handleBarcodeScan(isStockIn: true), // Call unified handler
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ActionButton(
                          title: 'Stock Out',
                          icon: Icons.qr_code_2_outlined,
                          color: const Color(0xFFF44336), // Changed to a more distinct red for stock out
                          onTap: () => _handleBarcodeScan(isStockIn: false), // Call unified handler
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    title: 'Export PDF Report',
                    icon: Icons.picture_as_pdf,
                    color: const Color(0xFF2196F3),
                    onTap: _exportToPDF,
                  ),
                  const SizedBox(height: 16), // Add spacing below the PDF button
                  // App Version Text
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'App Version: 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
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
    _animationController.dispose();
    super.dispose();
  }
}