import 'package:flutter/material.dart';

import '../theme/fb_colors.dart';
import '../theme/fb_text.dart';
import '../theme/fb_theme.dart';

/// 흰 카드 (radius 16 · 외곽선 1 · 그림자 없음). 고대비 모드에서는 진한 2px 테두리를 두릅니다.
class FbCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const FbCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.color});

  /// 목록 카드: 위아래 여백만 줄인 카드.
  const FbCard.list({super.key, required this.child, this.color})
    : padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8);

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Container(
      decoration: BoxDecoration(
        color: color ?? c.card,
        borderRadius: BorderRadius.circular(16),
        border: c.cardBorder != null ? Border.all(color: c.cardBorder!, width: c.cardBorderWidth) : null,
      ),
      padding: padding,
      child: child,
    );
  }
}

/// 카드 안의 제목 + 설명.
class CardTitle extends StatelessWidget {
  final String title;
  final String? desc;

  const CardTitle(this.title, {super.key, this.desc});

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: FbText.cardTitle(c))),
        const SizedBox(height: 4),
        if (desc != null) ...[Text(desc!, style: FbText.cardDesc(c)), const SizedBox(height: 12)],
      ],
    );
  }
}

/// 목록 카드 머리: 제목 + [전체보기]
class ListHead extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const ListHead(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Row(
      children: [
        Expanded(child: Semantics(header: true, child: Text(title, style: FbText.cardTitle(c)))),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: c.muted,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(44, 32),
              textStyle: const TextStyle(fontFamily: FbTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: Text(action!),
          ),
      ],
    );
  }
}

/// 화면 머리말 (.greet / .page-title).
class Greeting extends StatelessWidget {
  final String title;
  final String? sub;

  const Greeting(this.title, {super.key, this.sub});

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sub != null) ...[Text(sub!, style: FbText.greetSub(c)), const SizedBox(height: 4)],
          Semantics(header: true, child: Text(title, style: FbText.greet(c))),
        ],
      ),
    );
  }
}
