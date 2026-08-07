class PositionModel {
  final String symbol;
  final String stockName;
  final int quantity;
  final double avgBuyPrice;
  final double currentPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  PositionModel({
    required this.symbol,
    required this.stockName,
    required this.quantity,
    required this.avgBuyPrice,
    required this.currentPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalInvested => quantity * avgBuyPrice;
  double get currentValue => quantity * currentPrice;
  double get profitLoss => currentValue - totalInvested;
  double get profitLossPercent => (profitLoss / totalInvested) * 100;
  bool get isProfit => profitLoss >= 0;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'stockName': stockName,
    'quantity': quantity,
    'avgBuyPrice': avgBuyPrice,
    'currentPrice': currentPrice,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PositionModel.fromJson(Map<String, dynamic> json) => PositionModel(
    symbol: json['symbol'] as String,
    stockName: json['stockName'] as String,
    quantity: json['quantity'] as int,
    avgBuyPrice: (json['avgBuyPrice'] as num).toDouble(),
    currentPrice: (json['currentPrice'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  PositionModel copyWith({
    String? symbol,
    String? stockName,
    int? quantity,
    double? avgBuyPrice,
    double? currentPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PositionModel(
    symbol: symbol ?? this.symbol,
    stockName: stockName ?? this.stockName,
    quantity: quantity ?? this.quantity,
    avgBuyPrice: avgBuyPrice ?? this.avgBuyPrice,
    currentPrice: currentPrice ?? this.currentPrice,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
