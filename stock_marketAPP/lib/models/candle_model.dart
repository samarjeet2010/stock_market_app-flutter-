/// A single OHLC (open/high/low/close) candle for the stock chart, matching
/// the shape returned by GET /api/market/stocks/:symbol/candles.
class CandleModel {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  CandleModel({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  bool get isBullish => close >= open;

  factory CandleModel.fromJson(Map<String, dynamic> json) => CandleModel(
        time: DateTime.fromMillisecondsSinceEpoch((json['time'] as num).toInt()),
        open: (json['open'] as num).toDouble(),
        high: (json['high'] as num).toDouble(),
        low: (json['low'] as num).toDouble(),
        close: (json['close'] as num).toDouble(),
        volume: (json['volume'] as num).toInt(),
      );
}

/// Time ranges shown as tabs above the chart, same set a real trading app
/// (Angel One, Zerodha, etc.) offers.
enum ChartRange { d1, w1, m1, m3, y1 }

extension ChartRangeX on ChartRange {
  String get label => switch (this) {
        ChartRange.d1 => '1D',
        ChartRange.w1 => '1W',
        ChartRange.m1 => '1M',
        ChartRange.m3 => '3M',
        ChartRange.y1 => '1Y',
      };

  String get apiValue => label;
}
