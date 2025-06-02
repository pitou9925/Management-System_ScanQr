// lib/screens/stock_in_today_screen.dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/transaction.dart'; // NEW: Import Transaction model

class StockInTodayScreen extends StatelessWidget {
  final List<Product> products;
  final List<Transaction> transactions;

  const StockInTodayScreen({
    super.key,
    required this.products,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    // Get today's date in YYYY-MM-DD format
    final String todayKey = DateTime.now().toIso8601String().split('T')[0];

    // Filter transactions for stock-in events that happened today
    final List<Transaction> stockInToday = transactions.where((transaction) {
      final String transactionDay = transaction.timestamp.toIso8601String().split('T')[0];
      return transaction.transactionType == 'stock_in' && transactionDay == todayKey;
    }).toList();

    // Get unique product barcodes from today's stock-in transactions
    final Set<String> productBarcodesWithStockIn = stockInToday.map((t) => t.productBarcode).toSet();

    // Filter products that have stock-in transactions today
    final List<Product> productsWithStockInToday = products.where((product) {
      return productBarcodesWithStockIn.contains(product.barcode);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stock In Today',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: productsWithStockInToday.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No stock-in movements recorded today.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: productsWithStockInToday.length,
        itemBuilder: (context, index) {
          final product = productsWithStockInToday[index];
          // Calculate total stock-in quantity for this product today
          final int stockInQuantity = stockInToday
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
                        'Stock In Today: $stockInQuantity',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFFF9800),
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