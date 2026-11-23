import 'package:core_family/core_family.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import 'guardian_actions.dart';
import 'incident_summary_sheet.dart';

/// 거래 보류 및 보호자 확인 카드: 보류는 [해제]/[연장], 일반 요청은 [승인]/[거절]을 받습니다.
class RequestCard extends StatefulWidget {
  final ApprovalRequest request;
  final FamilySnapshot data;
  final DateTime Function() now;
  final ValueChanged<Member>? onCallMember;

  const RequestCard({
    super.key,
    required this.request,
    required this.data,
    required this.now,
    this.onCallMember,
  });

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  String? _busy; // 'approve' / 'reject' / 'extend'

  Future<void> _decide(bool approve) async {
    setState(() => _busy = approve ? 'approve' : 'reject');
    await decideRequest(context, widget.request.id, approve: approve);
    if (mounted) setState(() => _busy = null);
  }

  Future<void> _extend() async {
    setState(() => _busy = 'extend');
    await extendHoldRequest(context, widget.request.id);
    if (mounted) setState(() => _busy = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final r = widget.request;
    final m = widget.data.memberOrNull(r.memberId);
    final risk = r.risk;
    final isHold = r.isHold;
    final incident = isHold ? widget.data.incidentOrNull(r.incidentId) : null;
    final kindLabel = isHold ? '거래 보류' : '요청';
    final who = m?.label ?? '';
    // Figma 보호자 알림: 보류는 빨간 상자 안에 "시도가 보류됐어요"와 큰 남은 시간을 둡니다.
    final head = isHold
        ? Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.redSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border(left: BorderSide(color: c.red, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ExcludeSemantics(child: Icon(Icons.verified_user_outlined, size: 16, color: c.redStrong)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('핑거벨 · 위험 알림', style: TextStyle(fontSize: 12.8, fontWeight: FontWeight.w700, color: c.redStrong)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Semantics(
                  header: true,
                  child: Text(
                    '$who님의 ${r.title} 시도가 보류됐어요',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.35, letterSpacing: -.4, color: c.ink),
                  ),
                ),
                if (r.expiresAt != null && !r.isReconfirm) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('남은 시간 ', style: TextStyle(fontSize: 14.4, fontWeight: FontWeight.w700, color: c.redStrong)),
                      CountdownText(
                        until: r.expiresAt!,
                        now: widget.now,
                        format: formatMinSec,
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1, color: c.redStrong),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                if (r.amount > 0) Text(won(r.amount), style: FbText.bigAmount(c)),
                Text(
                  r.amount > 0 ? r.title : r.detail,
                  style: TextStyle(fontSize: 14.4, fontWeight: FontWeight.w700, color: c.ink2),
                ),
                Text('${formatWhen(r.createdAt, widget.now())} · $kindLabel', style: FbText.small(c)),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$who님의 $kindLabel · ${formatWhen(r.createdAt, widget.now())}',
                style: TextStyle(fontSize: 13.6, fontWeight: FontWeight.w600, color: c.muted),
              ),
              const SizedBox(height: 5.6),
              Text(r.amount > 0 ? won(r.amount) : r.title, style: FbText.bigAmount(c)),
              const SizedBox(height: 2.4),
              Text(r.amount > 0 ? '${r.title} · ${r.detail}' : r.detail, style: TextStyle(fontSize: 13.8, color: c.ink2)),
            ],
          );
    return FbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head,
          const SizedBox(height: 16),
          if (risk != null) ...[
            RiskLevelMeter(level: risk.level.index),
            const SizedBox(height: 10),
            RiskBox(
              title: 'AI 위험도 ${risk.score}점 · ${risk.level.label}',
              danger: !risk.isSafe,
              items: [for (final s in risk.signals) s.label],
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 2,
            children: [
              Icon(FbIcons.bell, size: 15, color: c.muted),
              const SizedBox(width: 5),
              Text('앱 알림', style: FbText.small(c)),
              if (r.isReconfirm)
                Text(' · 본인 재확인 대기 중', style: FbText.small(c).copyWith(fontWeight: FontWeight.w800, color: c.redStrong))
              else if (r.expiresAt != null) ...[
                Text(isHold ? ' · 보류 남은 시간 ' : ' · 남은 시간 ', style: FbText.small(c)),
                CountdownText(
                  until: r.expiresAt!,
                  now: widget.now,
                  format: formatMinSec,
                  style: FbText.small(c).copyWith(fontWeight: FontWeight.w800, color: c.ink2),
                ),
              ],
            ],
          ),
          if (incident != null) ...[
            const SizedBox(height: 12),
            FbButton(
              '위험 근거 요약 보기',
              icon: FbIcons.list,
              onPressed: () => openIncidentSummarySheet(
                context,
                incidentId: incident.id,
                initialIncident: incident,
                member: m,
                now: widget.now,
                onCallMember: widget.onCallMember,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (isHold)
            FbButtonRow(
              children: [
                FbButton.gray('연장', busy: _busy == 'extend', onPressed: _busy == null ? _extend : null),
                FbButton.gray('해제', busy: _busy == 'approve', onPressed: _busy == null ? () => _decide(true) : null),
              ],
            )
          else
            FbButtonRow(
              children: [
                FbButton.gray('거절', busy: _busy == 'reject', onPressed: _busy == null ? () => _decide(false) : null),
                FbButton('승인', busy: _busy == 'approve', onPressed: _busy == null ? () => _decide(true) : null),
              ],
            ),
        ],
      ),
    );
  }
}
