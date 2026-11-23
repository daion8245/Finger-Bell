import 'package:core_family/core_family.dart';
import 'package:core_shell/core_shell.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'call_sheet.dart';
import 'message_sheet.dart';
import 'sip_phone.dart';

/// 가족 내선 → 이름. 내선은 사용자 Persona 이름입니다 (보호자 guardian, 가족은 사용자 id senior·child).
Map<String, String> familyContacts(FamilySnapshot data) => {
  Persona.guardian.name: data.guardian.name,
  for (final m in data.members) m.id: m.name,
};

/// [peer]에게 인터넷 전화를 걸고 통화 화면을 엽니다.
Future<void> startCall(BuildContext context, {required String peer, required String name}) async {
  final phone = context.read<SipPhone?>();
  if (phone == null || !await phone.call(peer)) {
    if (context.mounted) context.read<ShellCubit>().say('전화 서버에 연결되지 않았어요. 같은 Wi-Fi인지 확인해 주세요');
    return;
  }
  if (context.mounted) await openCallSheet(context, name: name);
}

/// 가족에게 전화·문자. [contacts]는 나를 뺀 가족 (내선 → 이름).
class FamilyContactsCard extends StatelessWidget {
  final Map<String, String> contacts;

  const FamilyContactsCard({super.key, required this.contacts});

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final online = context.select((SipPhone p) => p.state.online);
    return FbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            '가족 연락',
            desc: online ? '같은 Wi-Fi의 가족 핑거벨 앱으로 전화·문자해요' : '전화 서버(Asterisk)에 연결하는 중이에요',
          ),
          for (final e in contacts.entries)
            FbListRow(
              leading: TxLogo.initial(e.value, blue: true),
              title: Text(e.value),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: '${e.value}님께 문자',
                    onPressed: () => openMessageSheet(context, peer: e.key, name: e.value),
                    icon: Icon(Icons.chat_bubble_outline_rounded, color: c.blue, size: 20),
                  ),
                  IconButton(
                    tooltip: '${e.value}님께 전화',
                    onPressed: () => startCall(context, peer: e.key, name: e.value),
                    icon: Icon(FbIcons.phone, color: c.blue, size: 20),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
