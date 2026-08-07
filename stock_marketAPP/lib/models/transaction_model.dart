class TransactionModel {
  final String transactionId;
  final String userId;
  final String symbol;
  final String stockName;
  final String type;
  final int quantity;
  final double price;
  final double totalAmount;
  final DateTime timestamp;

  TransactionModel({
    required this.transactionId,
    required this.userId,
    required this.symbol,
    required this.stockName,
    required this.type,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.timestamp,
  });

  bool get isBuy => type == 'buy';
  bool get isSell => type == 'sell';

  Map<String, dynamic> toJson() => {
    'transactionId': transactionId,
    'userId': userId,
    'symbol': symbol,
    'stockName': stockName,
    'type': type,
    'quantity': quantity,
    'price': price,
    'totalAmount': totalAmount,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    transactionId: json['transactionId'] as String,
    userId: json['userId'] as String,
    symbol: json['symbol'] as String,
    stockName: json['stockName'] as String,
    type: json['type'] as String,
    quantity: json['quantity'] as int,
    price: (json['price'] as num).toDouble(),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  TransactionModel copyWith({
    String? transactionId,
    String? userId,
    String? symbol,
    String? stockName,
    String? type,
    int? quantity,
    double? price,
    double? totalAmount,
    DateTime? timestamp,
  }) => TransactionModel(
    transactionId: transactionId ?? this.transactionId,
    userId: userId ?? this.userId,
    symbol: symbol ?? this.symbol,
    stockName: stockName ?? this.stockName,
    type: type ?? this.type,
    quantity: quantity ?? this.quantity,
    price: price ?? this.price,
    totalAmount: totalAmount ?? this.totalAmount,
    timestamp: timestamp ?? this.timestamp,
  );
}
