import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../core/database/database_helper.dart';
import '../core/ssia/ssia_engine.dart';
import '../models/category.dart';

/// CSV Import Service
/// Handles CSV file import and batch processing
class CSVImportService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Pick and import CSV file
  Future<CSVImportResult> importCSV() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        return CSVImportResult(
          success: false,
          message: 'No file selected',
        );
      }

      final file = File(result.files.first.path!);
      
      // Read and parse CSV
      final csvString = await file.readAsString();
      final csvData = const CsvToListConverter().convert(csvString);

      if (csvData.isEmpty) {
        return CSVImportResult(
          success: false,
          message: 'CSV file is empty',
        );
      }

      // Parse transactions
      final parseResult = _parseCSVData(csvData);
      
      if (!parseResult.success) {
        return CSVImportResult(
          success: false,
          message: parseResult.message ?? 'Unknown error',
        );
      }

      // Process through SSIA
      final fingerprint = await _db.getSpendingFingerprint();
      
      final batchResult = await SSIAEngine.batchProcess(
        rawTransactions: parseResult.transactions!,
        fingerprint: fingerprint,
      );

      // Save to database
      await _db.batchInsertTransactions(batchResult.transactions);
      await _db.updateSpendingFingerprint(batchResult.finalFingerprint);
      await _db.batchInsertAlerts(batchResult.alerts);

      return CSVImportResult(
        success: true,
        message: 'Successfully imported ${batchResult.transactions.length} transactions',
        transactionCount: batchResult.transactions.length,
        alertCount: batchResult.alerts.length,
      );
    } catch (e) {
      return CSVImportResult(
        success: false,
        message: 'Error importing CSV: $e',
      );
    }
  }

  /// Parse CSV data
  /// Expected format: amount, merchant, date, paymentMode, category (optional), note (optional)
  _ParseResult _parseCSVData(List<List<dynamic>> csvData) {
    try {
      final transactions = <Map<String, dynamic>>[];
      
      // Skip header row if present
      int startRow = 0;
      if (csvData[0].any((cell) => cell.toString().toLowerCase().contains('amount'))) {
        startRow = 1;
      }

      for (int i = startRow; i < csvData.length; i++) {
        final row = csvData[i];
        
        if (row.length < 4) {
          return _ParseResult(
            success: false,
            message: 'Invalid CSV format at row ${i + 1}. Expected at least 4 columns.',
          );
        }

        try {
          final amount = double.parse(row[0].toString());
          final merchant = row[1].toString().trim();
          final dateStr = row[2].toString().trim();
          final paymentMode = row[3].toString().trim();
          
          // Parse date (support multiple formats)
          DateTime timestamp;
          try {
            timestamp = DateTime.parse(dateStr);
          } catch (e) {
            // Try alternative formats
            timestamp = _parseFlexibleDate(dateStr);
          }

          // Optional category
          String? category;
          if (row.length > 4 && row[4].toString().trim().isNotEmpty) {
            category = row[4].toString().trim();
          } else {
            // Auto-detect
            category = ExpenseCategory.detectCategory(merchant);
          }

          // Optional note
          String? note;
          if (row.length > 5 && row[5].toString().trim().isNotEmpty) {
            note = row[5].toString().trim();
          }

          transactions.add({
            'amount': amount,
            'merchant': merchant,
            'timestamp': timestamp,
            'paymentMode': paymentMode,
            'category': category,
            'note': note,
          });
        } catch (e) {
          return _ParseResult(
            success: false,
            message: 'Error parsing row ${i + 1}: $e',
          );
        }
      }

      return _ParseResult(
        success: true,
        transactions: transactions,
      );
    } catch (e) {
      return _ParseResult(
        success: false,
        message: 'Error parsing CSV: $e',
      );
    }
  }

  /// Parse flexible date formats
  DateTime _parseFlexibleDate(String dateStr) {
    // Try common formats
    final formats = [
      // ISO formats
      RegExp(r'(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})'),
      // DD/MM/YYYY HH:MM
      RegExp(r'(\d{2})/(\d{2})/(\d{4})\s+(\d{2}):(\d{2})'),
      // DD-MM-YYYY HH:MM
      RegExp(r'(\d{2})-(\d{2})-(\d{4})\s+(\d{2}):(\d{2})'),
    ];

    for (final format in formats) {
      final match = format.firstMatch(dateStr);
      if (match != null) {
        if (match.groupCount >= 5) {
          // Check if first group is year (4 digits) or day (2 digits)
          if (match.group(1)!.length == 4) {
            // YYYY-MM-DD HH:MM
            return DateTime(
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
              int.parse(match.group(4)!),
              int.parse(match.group(5)!),
            );
          } else {
            // DD/MM/YYYY HH:MM or DD-MM-YYYY HH:MM
            return DateTime(
              int.parse(match.group(3)!),
              int.parse(match.group(2)!),
              int.parse(match.group(1)!),
              int.parse(match.group(4)!),
              int.parse(match.group(5)!),
            );
          }
        }
      }
    }

    // Fallback: try DateTime.parse
    return DateTime.parse(dateStr);
  }

  /// Generate sample CSV for download
  String generateSampleCSV() {
    final rows = [
      ['amount', 'merchant', 'date', 'paymentMode', 'category', 'note'],
      ['150.50', 'Swiggy', '2025-12-28 14:30', 'UPI', 'Food', 'Lunch order'],
      ['50.00', 'Metro Card', '2025-12-28 09:15', 'Card', 'Transport', 'Daily commute'],
      ['999.00', 'Netflix', '2025-12-01 00:00', 'Subscription', 'Subscriptions', 'Monthly subscription'],
      ['250.00', 'Amazon', '2025-12-27 18:45', 'UPI', 'Shopping', 'Books'],
      ['80.00', 'Canteen', '2025-12-28 13:00', 'Cash', 'Food', 'Lunch'],
    ];

    return const ListToCsvConverter().convert(rows);
  }
}

/// CSV Import Result
class CSVImportResult {
  final bool success;
  final String message;
  final int? transactionCount;
  final int? alertCount;

  CSVImportResult({
    required this.success,
    required this.message,
    this.transactionCount,
    this.alertCount,
  });
}

/// Internal parse result
class _ParseResult {
  final bool success;
  final String? message;
  final List<Map<String, dynamic>>? transactions;

  _ParseResult({
    required this.success,
    this.message,
    this.transactions,
  });
}
