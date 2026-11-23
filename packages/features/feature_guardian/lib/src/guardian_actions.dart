import 'package:core_api/core_api.dart';
import 'package:core_family/core_family.dart';
import 'package:core_shell/core_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 보호자가 승인/거절하고, 결과를 안내합니다.
Future<void> decideRequest(BuildContext context, String requestId, {required bool approve}) async {
  final family = context.read<FamilyCubit>();
  final shell = context.read<ShellCubit>();
  final req = family.state.isReady ? family.state.data.request(requestId) : null;
  final who = req == null ? '' : family.state.data.memberOrNull(req.memberId)?.relationLabel ?? '';
  try {
    final r = await family.decide(requestId, approve: approve);
    final msg = switch (r.status) {
      'approved' => '승인했어요 · $who께 결과를 알렸어요',
      'rejected' => '거절했어요 · $who께 결과를 알렸어요',
      _ => '처리하지 못했어요 · ${r.message}',
    };
    shell.say(msg, vibrate: const [60]);
  } on ApiException catch (e) {
    shell.say(e.code == 'done' ? '이미 처리된 요청이에요' : e.message);
  }
}

Future<void> guardianRun(BuildContext context, Future<void> Function(FamilyCubit) action, String done) async {
  final shell = context.read<ShellCubit>();
  try {
    await action(context.read<FamilyCubit>());
    if (done.isNotEmpty) shell.say(done);
  } on ApiException catch (e) {
    shell.say(e.message);
  }
}
