import 'package:flutter/material.dart';

import 'layout.dart';
import 'theme/fb_colors.dart';
import 'theme/fb_icons.dart';
import 'theme/fb_text.dart';

/// 모바일은 바텀 시트, 웹은 가운데 모달로 엽니다.
///
/// 경로 이름은 붙이지 않습니다. 이름이 있으면 웹 주소창이 `#transfer`처럼 바뀌어,
/// 새로고침할 때 없는 경로로 시작하게 됩니다.
Future<T?> showFbSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  const settings = RouteSettings();
  if (FbLayout.isWebOf(context)) {
    return showDialog<T>(
      context: context,
      routeSettings: settings,
      barrierColor: const Color(0x66000000),
      builder: (ctx) => FbLayout(
        isWeb: true,
        child: Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 460, maxHeight: MediaQuery.sizeOf(ctx).height * .88),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: builder(ctx),
            ),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    routeSettings: settings,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: const Color(0x66000000),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    clipBehavior: Clip.antiAlias,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
    builder: (ctx) => FbLayout(
      isWeb: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: ctx.fb.faint, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              builder(ctx),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 시트 머리: [뒤로] 제목 [닫기]
class SheetHead extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  const SheetHead({super.key, this.title = '', this.onBack, this.onClose});

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            if (onBack != null)
              Transform.translate(
                offset: const Offset(-8, 0),
                child: IconButton(
                  onPressed: onBack,
                  tooltip: '뒤로',
                  icon: Icon(FbIcons.back, color: c.ink2, size: 26),
                ),
              ),
            Expanded(
              child: Semantics(header: true, child: Text(title, style: FbText.sheetTitle(c))),
            ),
            IconButton(
              onPressed: onClose ?? () => Navigator.of(context).maybePop(),
              tooltip: '닫기',
              icon: Icon(FbIcons.close, color: c.ink2, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
