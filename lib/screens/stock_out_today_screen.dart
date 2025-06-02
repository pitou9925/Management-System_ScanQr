// lib/screens/stock_out_today_screen.dart
import 'package:flutter/material.dart';
import '../models/product.dart'; // Make sure this path is correct
import '../models/transaction.dart'; // NEW: Import the Transaction model

class StockOutTodayScreen extends StatelessWidget {
  final List<Product> products; // Renamed from stockOutProducts
  final List<Transaction> transactions; // NEW: Add transactions list

  const StockOutTodayScreen({
    super.key,
    required this.products, // Now explicitly required
    required this.transactions, // Now explicitly required
  });

  @override
  Widget build(BuildContext context) {
    // Get today's date in YYYY-MM-DD format
    final String todayKey = DateTime.now().toIso8601String().split('T')[0];

    // Filter transactions for stock-out events that happened today
    final List<Transaction> stockOutTodayTransactions = transactions.where((transaction) {
      final String transactionDay = transaction.timestamp.toIso8601String().split('T')[0];
      return transaction.transactionType == 'stock_out' && transactionDay == todayKey;
    }).toList();

    // Get unique product barcodes from today's stock-out transactions
    final Set<String> productBarcodesWithStockOut = stockOutTodayTransactions.map((t) => t.productBarcode).toSet();

    // Filter products that correspond to stock-out transactions today
    final List<Product> productsWithStockOutToday = products.where((product) {
      return productBarcodesWithStockOut.contains(product.barcode);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stock Out Today',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: const Color(0xFFF44336), // Red for stock out
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: productsWithStockOutToday.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No stock-out movements recorded today.', // Accurate message now!
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: productsWithStockOutToday.length,
        itemBuilder: (context, index) {
          final product = productsWithStockOutToday[index];
          // Calculate total stock-out quantity for this specific product today
          final int stockOutQuantity = stockOutTodayTransactions
              .where((t) => t.productBarcode == product.barcode)
              .fold(0, (sum, t) => sum + t.quantity);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Barcode: ${product.barcode}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Category: ${product.category}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stock Out Today: $stockOutQuantity', // Display actual stock out quantity
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFF44336), // Red for stock out quantity
                        ),
                      ),
                      Text(
                        'Current Quantity: ${product.quantity}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Price: \$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Updated: ${product.updatedAt.toLocal().toString().split('.')[0]}',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}