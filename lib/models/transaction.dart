// lib/models/transaction.dart
import 'package:flutter/foundation.dart'; // For @required if not using null safety

class Transaction {
  final String productBarcode;
  final int quantity; // Quantity added or removed
  final DateTime timestamp;
  final String transactionType; // 'stock_in' or 'stock_out'

  Transaction({
    required this.productBarcode,
    required this.quantity,
    required this.timestamp,
    required this.transactionType,
  });

  // Convert a Transaction object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'productBarcode': productBarcode,
      'quantity': quantity,
      'timestamp': timestamp.toIso8601String(), // Store DateTime as ISO 8601 string
      'transactionType': transactionType,
    };
  }

  // Create a Transaction object from a JSON map
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      productBarcode: json['productBarcode'],
      quantity: json['quantity'],
      timestamp: DateTime.parse(json['timestamp']), // Parse ISO 8601 string back to DateTime
      transactionType: json['transactionType'],
    );
  }
}