import 'package:flutter/material.dart';

import '../sheet.dart';
import '../theme/fb_colors.dart';
import '../theme/fb_icons.dart';
import '../theme/fb_text.dart';
import 'buttons.dart';

/// 주의 모드 중 감시 대상 금융 행동을 시도할 때 띄우는 공통 확인 질문 화면 (기획서 5.6).
///
/// - 한 화면에 질문 하나만 보여 줍니다.
/// - 큰 버튼 객관식만 제공하며, 어느 선택지도 미리 선택하거나 강조하지 않습니다.
/// - 시간 제한을 두지 않습니다.
/// - 화면이 열리면 TalkBack 초점을 질문 제목으로 옮기고, 읽는 순서대로 이동합니다.
class ConfirmationQuestionView extends StatefulWidget {
  final String question;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final VoidCallback? onAskGuardian;
  final bool busy;

  const ConfirmationQuestionView({
    super.key,
    required this.question,
    required this.options,
    required this.onSelected,
    this.onBack,
    this.onClose,
    this.onAskGuardian,
    this.busy = false,
  });

  @override
  State<ConfirmationQuestionView> createState() => _ConfirmationQuestionViewState();
}

class _ConfirmationQuestionViewState extends State<ConfirmationQuestionView> {
  final _questionFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _questionFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _questionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHead(title: '잠깐만 확인해요', onBack: widget.onBack, onClose: widget.onClose),
          Row(
            children: [
              ExcludeSemantics(child: Icon(Icons.verified_user_outlined, size: 16, color: c.blue)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '주의 모드 확인 질문',
                  style: TextStyle(fontSize: 13.2, fontWeight: FontWeight.w700, color: c.blueStrong),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Focus(
            focusNode: _questionFocus,
            child: Semantics(
              liveRegion: true,
              header: true,
              child: Text(
                widget.question,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.4, letterSpacing: -.5, color: c.ink),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '시간 제한이 없어요. 천천히 읽고 가장 가까운 답을 눌러 주세요.',
            style: FbText.hint(c),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < widget.options.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _OptionButton(
              optionKey: ValueKey('caution-option-$i'),
              label: widget.options[i],
              busy: widget.busy,
              onTap: widget.busy ? null : () => widget.onSelected(widget.options[i]),
            ),
          ],
          if (widget.onAskGuardian != null) ...[
            const SizedBox(height: 16),
            FbButton.gray(
              '보호자에게 물어보기',
              icon: FbIcons.phone,
              onPressed: widget.busy ? null : widget.onAskGuardian,
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final Key optionKey;
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  const _OptionButton({required this.optionKey, required this.label, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    // Figma ChoiceButton: 흰 바탕 + 왼쪽 빈 동그라미. 미리 고르거나 강조한 선택지는 두지 않습니다.
    return Semantics(
      key: optionKey,
      button: true,
      selected: false,
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 57, minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.cardBorder ?? c.line, width: c.cardBorder != null ? 1.5 : 1.2),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.faint, width: 2)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.45, color: c.ink),
                  ),
                ),
                if (busy) ...[
                  const SizedBox(width: 8),
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: c.blue)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
