class StockModel {
  final String symbol;
  final String name;
  final double currentPrice;
  final double change;
  final double changePercent;
  final int volume;
  final double? marketCap;
  final double? high;
  final double? low;
  final String? sector;
  final String? description;
  final DateTime updatedAt;
  final List<double> priceHistory;

  StockModel({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.volume,
    this.marketCap,
    this.high,
    this.low,
    this.sector,
    this.description,
    required this.updatedAt,
    required this.priceHistory,
  });

  bool get isPositive => change >= 0;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'currentPrice': currentPrice,
    'change': change,
    'changePercent': changePercent,
    'volume': volume,
    'marketCap': marketCap,
    'high': high,
    'low': low,
    'sector': sector,
    'description': description,
    'updatedAt': updatedAt.toIso8601String(),
    'priceHistory': priceHistory,
  };

  factory StockModel.fromJson(Map<String, dynamic> json) => StockModel(
    symbol: json['symbol'] as String,
    name: json['name'] as String,
    currentPrice: (json['currentPrice'] as num).toDouble(),
    change: (json['change'] as num).toDouble(),
    changePercent: (json['changePercent'] as num).toDouble(),
    volume: json['volume'] as int,
    marketCap: json['marketCap'] != null ? (json['marketCap'] as num).toDouble() : null,
    high: json['high'] != null ? (json['high'] as num).toDouble() : null,
    low: json['low'] != null ? (json['low'] as num).toDouble() : null,
    sector: json['sector'] as String?,
    description: json['description'] as String?,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    priceHistory: (json['priceHistory'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [(json['currentPrice'] as num).toDouble()],
  );

  StockModel copyWith({
    String? symbol,
    String? name,
    double? currentPrice,
    double? change,
    double? changePercent,
    int? volume,
    double? marketCap,
    double? high,
    double? low,
    String? sector,
    String? description,
    DateTime? updatedAt,
    List<double>? priceHistory,
  }) => StockModel(
    symbol: symbol ?? this.symbol,
    name: name ?? this.name,
    currentPrice: currentPrice ?? this.currentPrice,
    change: change ?? this.change,
    changePercent: changePercent ?? this.changePercent,
    volume: volume ?? this.volume,
    marketCap: marketCap ?? this.marketCap,
    high: high ?? this.high,
    low: low ?? this.low,
    sector: sector ?? this.sector,
    description: description ?? this.description,
    updatedAt: updatedAt ?? this.updatedAt,
    priceHistory: priceHistory ?? this.priceHistory,
  );
}
