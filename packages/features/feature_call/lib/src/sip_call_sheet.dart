import 'package:core_shell/core_shell.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sip_phone.dart';

/// 가족 인터넷 전화(SIP) 통화 화면 (걸 때·걸려 올 때 모두). 시트를 닫으면 전화를 끊습니다.
Future<void> openSipCallSheet(BuildContext context, {required String name}) =>
    showFbSheet<void>(context, builder: (_) => SipCallSheet(name: name));

class SipCallSheet extends StatelessWidget {
  final String name;

  const SipCallSheet({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final phone = context.read<SipPhone>();
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) phone.hangup();
      },
      child: BlocConsumer<SipPhone, PhoneState>(
        listenWhen: (a, b) => a.call != null && b.call == null,
        listener: (context, s) {
          if (s.notice != null) context.read<ShellCubit>().say(s.notice!, vibrate: const []);
          Navigator.of(context).maybePop();
        },
        builder: (context, s) {
          final ringing = s.call != null && s.incoming && !s.answered;
          final status = s.call == null
              ? (s.notice ?? '통화를 마쳤어요')
              : s.answered
              ? '통화 중이에요'
              : ringing
              ? '인터넷 전화가 왔어요'
              : '전화를 거는 중이에요…';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHead(title: '인터넷 전화'),
              CenterBlock(
                icon: ResultIcon(FbIcons.phone, tone: ResultTone.soft, ringing: s.call != null && !s.answered),
                title: name,
                body: status,
              ),
              const SizedBox(height: 22.4),
              if (s.call == null)
                FbButton('닫기', onPressed: () => Navigator.of(context).maybePop())
              else if (ringing)
                FbButtonRow(
                  children: [
                    FbButton.gray('거절', onPressed: phone.hangup),
                    FbButton('받기', icon: FbIcons.phone, onPressed: phone.answer),
                  ],
                )
              else
                FbButton('끊기', variant: FbButtonVariant.red, icon: FbIcons.phone, onPressed: phone.hangup),
            ],
          );
        },
      ),
    );
  }
}
