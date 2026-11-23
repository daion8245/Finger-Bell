import 'dart:async';

import 'package:flutter/material.dart';

import '../format.dart';
import '../theme/fb_colors.dart';
import '../theme/fb_text.dart';

/// 남은 시간을 1초마다 다시 그립니다. [now]는 서버 기준 현재 시각입니다.
class CountdownText extends StatefulWidget {
  final DateTime until;
  final DateTime Function() now;
  final String Function(Duration) format;
  final TextStyle? style;

  const CountdownText({
    super.key,
    required this.until,
    required this.now,
    this.format = formatCountdown,
    this.style,
  });

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.until.difference(widget.now());
    return Text(
      widget.format(left.isNegative ? Duration.zero : left),
      style: (widget.style ?? const TextStyle()).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}

/// 원형 카운트다운 (Figma "원형 카운트다운"): 고리는 [total] 중 남은 비율, 가운데는 "29:12"와 [caption].
class CountdownRing extends StatefulWidget {
  final DateTime until;
  final DateTime Function() now;
  final Duration total;
  final String caption;
  final Color? color;
  final double size;

  const CountdownRing({
    super.key,
    required this.until,
    required this.now,
    this.total = const Duration(minutes: 30),
    this.caption = '',
    this.color,
    this.size = 132,
  });

  @override
  State<CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<CountdownRing> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final raw = widget.until.difference(widget.now());
    final left = raw.isNegative ? Duration.zero : raw;
    final total = widget.total.inSeconds;
    final fraction = total <= 0 ? 0.0 : (left.inSeconds / total).clamp(0.0, 1.0);
    final color = widget.color ?? c.blue;
    final text = formatMinSec(left);
    // 큰 글씨에서는 고리도 함께 키우고, 그래도 넘치면 가운데 글자를 고리 안에 맞춥니다.
    final dimension = widget.size * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8);
    return Center(
      child: Semantics(
        label: '${widget.caption.isEmpty ? '' : '${widget.caption}, '}남은 시간 $text',
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: dimension,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: fraction,
                strokeWidth: widget.size * .075,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: c.soft,
              ),
              Padding(
                padding: EdgeInsets.all(dimension * .14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text,
                        style: FbText.tabular(
                          TextStyle(fontSize: widget.size * .22, fontWeight: FontWeight.w800, letterSpacing: -1, color: color),
                        ),
                      ),
                      if (widget.caption.isNotEmpty)
                        Text(widget.caption, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.muted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
