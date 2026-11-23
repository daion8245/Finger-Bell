import 'package:flutter/material.dart';

import '../theme/fb_colors.dart';

/// 방패 브랜드 마크 + 앱 이름 글자 (Figma TopAppBar: 남보라 방패와 "핑거벨").
class Brand extends StatelessWidget {
  final bool showWordmark;
  final double size;
  final String label;

  const Brand({super.key, this.showWordmark = true, this.size = 18, this.label = '핑거벨'});

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Semantics(
      label: label,
      image: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: size + 6, color: c.blue),
          if (showWordmark) ...[
            const SizedBox(width: 6),
            Flexible(
              child: ExcludeSemantics(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: -.6, color: c.blue),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
