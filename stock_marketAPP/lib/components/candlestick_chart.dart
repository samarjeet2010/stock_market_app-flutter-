import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled_5/models/candle_model.dart';
import 'package:untitled_5/theme.dart';
import 'package:untitled_5/utils/formatters.dart';

/// A self-contained, professional-looking OHLC candlestick chart with
/// range tabs (1D/1W/1M/3M/1Y) and a drag-to-inspect crosshair, styled to
/// resemble a real broker app (Angel One / Zerodha style).
///
/// [onRangeChanged] is called whenever the user taps a different range tab;
/// the caller is responsible for fetching new candles and passing them back
/// in via [candles] (see StockDetailScreen for the wiring).
class CandlestickChartCard extends StatefulWidget {
  final List<CandleModel> candles;
  final ChartRange selectedRange;
  final ValueChanged<ChartRange> onRangeChanged;
  final bool isLoading;

  const CandlestickChartCard({
    super.key,
    required this.candles,
    required this.selectedRange,
    required this.onRangeChanged,
    this.isLoading = false,
  });

  @override
  State<CandlestickChartCard> createState() => _CandlestickChartCardState();
}

class _CandlestickChartCardState extends State<CandlestickChartCard> {
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    final candles = widget.candles;
    final isPositive = candles.length >= 2 ? candles.last.close >= candles.first.open : true;
    final lineColor = isPositive ? LightModeColors.profitGreen : LightModeColors.lossRed;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hoverIndex != null && _hoverIndex! < candles.length)
              _CrosshairInfo(candle: candles[_hoverIndex!])
            else if (candles.isNotEmpty)
              _CrosshairInfo(candle: candles.last, isLive: true),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : candles.isEmpty
                      ? Center(
                          child: Text(
                            'No chart data',
                            style: context.textStyles.bodyMedium?.withColor(
                              Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onPanDown: (d) => _updateHover(d.localPosition, context),
                          onPanUpdate: (d) => _updateHover(d.localPosition, context),
                          onPanEnd: (_) => setState(() => _hoverIndex = null),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _CandlestickPainter(
                              candles: candles,
                              lineColor: lineColor,
                              gridColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                              hoverIndex: _hoverIndex,
                              isDark: Theme.of(context).brightness == Brightness.dark,
                            ),
                          ),
                        ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ChartRange.values.map((r) {
                final selected = r == widget.selectedRange;
                return GestureDetector(
                  onTap: () => widget.onRangeChanged(r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      r.label,
                      style: context.textStyles.bodySmall?.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _updateHover(Offset localPosition, BuildContext context) {
    final candles = widget.candles;
    if (candles.isEmpty) return;
    final box = context.findRenderObject();
    double width = 300;
    if (box is RenderBox) width = box.size.width;
    final chartWidth = width - 24; // matches painter padding
    final ratio = ((localPosition.dx - 12) / chartWidth).clamp(0.0, 1.0);
    final idx = (ratio * (candles.length - 1)).round().clamp(0, candles.length - 1);
    setState(() => _hoverIndex = idx);
  }
}

class _CrosshairInfo extends StatelessWidget {
  final CandleModel candle;
  final bool isLive;

  const _CrosshairInfo({required this.candle, this.isLive = false});

  @override
  Widget build(BuildContext context) {
    final color = candle.isBullish ? LightModeColors.profitGreen : LightModeColors.lossRed;
    final dateFmt = DateFormat('d MMM, HH:mm');
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: 2,
            children: [
              _ohlcTag('O', candle.open, context),
              _ohlcTag('H', candle.high, context),
              _ohlcTag('L', candle.low, context),
              _ohlcTag('C', candle.close, context, color: color),
            ],
          ),
        ),
        Text(
          isLive ? 'Live' : dateFmt.format(candle.time),
          style: context.textStyles.bodySmall?.withColor(
            isLive ? LightModeColors.profitGreen : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _ohlcTag(String label, double value, BuildContext context, {Color? color}) {
    return RichText(
      text: TextSpan(
        style: context.textStyles.bodySmall,
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          TextSpan(
            text: Formatters.inr(value),
            style: TextStyle(
              color: color ?? Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<CandleModel> candles;
  final Color lineColor;
  final Color gridColor;
  final int? hoverIndex;
  final bool isDark;

  _CandlestickPainter({
    required this.candles,
    required this.lineColor,
    required this.gridColor,
    required this.hoverIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    const leftPad = 4.0;
    const rightPad = 8.0;
    const topPad = 6.0;
    const bottomPad = 6.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    double minP = candles.first.low;
    double maxP = candles.first.high;
    for (final c in candles) {
      if (c.low < minP) minP = c.low;
      if (c.high > maxP) maxP = c.high;
    }
    final range = (maxP - minP) == 0 ? 1.0 : (maxP - minP);
    // Pad the price range a little so candles don't touch the edges.
    minP -= range * 0.06;
    maxP += range * 0.06;
    final paddedRange = maxP - minP;

    double yFor(double price) => topPad + chartHeight - ((price - minP) / paddedRange) * chartHeight;

    // --- gridlines ---
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = topPad + chartHeight * (i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);
    }

    final slotWidth = chartWidth / candles.length;
    final bodyWidth = (slotWidth * 0.6).clamp(1.5, 14.0);

    // --- area/line under close prices for a subtle "live" feel ---
    final linePath = Path();
    final fillPath = Path();
    for (int i = 0; i < candles.length; i++) {
      final x = leftPad + slotWidth * i + slotWidth / 2;
      final y = yFor(candles[i].close);
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height - bottomPad);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(leftPad + slotWidth * (candles.length - 1) + slotWidth / 2, size.height - bottomPad);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withValues(alpha: 0.16), lineColor.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // --- candles ---
    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = leftPad + slotWidth * i + slotWidth / 2;
      final bullish = c.isBullish;
      final color = bullish ? LightModeColors.profitGreen : LightModeColors.lossRed;
      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1.4;
      final bodyPaint = Paint()..color = color;

      // wick
      canvas.drawLine(Offset(x, yFor(c.high)), Offset(x, yFor(c.low)), wickPaint);

      // body
      final openY = yFor(c.open);
      final closeY = yFor(c.close);
      final top = openY < closeY ? openY : closeY;
      final bottom = openY < closeY ? closeY : openY;
      final bodyRect = Rect.fromLTRB(x - bodyWidth / 2, top, x + bodyWidth / 2, (bottom - top).abs() < 1 ? top + 1 : bottom);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(1.5)),
        bodyPaint,
      );
    }

    // --- crosshair ---
    if (hoverIndex != null && hoverIndex! < candles.length) {
      final i = hoverIndex!;
      final x = leftPad + slotWidth * i + slotWidth / 2;
      final crosshairPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(x, topPad), Offset(x, size.height - bottomPad), crosshairPaint);
      final y = yFor(candles[i].close);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), crosshairPaint);
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = lineColor);
      canvas.drawCircle(Offset(x, y), 3.5, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter oldDelegate) {
    return oldDelegate.candles != candles || oldDelegate.hoverIndex != hoverIndex || oldDelegate.isDark != isDark;
  }
}
