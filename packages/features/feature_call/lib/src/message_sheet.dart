import 'package:core_shell/core_shell.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sip_phone.dart';

/// [peer]와 주고받은 문자와 보내기 칸.
Future<void> openMessageSheet(BuildContext context, {required String peer, required String name}) =>
    showFbSheet<void>(context, builder: (_) => MessageSheet(peer: peer, name: name));

class MessageSheet extends StatefulWidget {
  final String peer;
  final String name;

  const MessageSheet({super.key, required this.peer, required this.name});

  @override
  State<MessageSheet> createState() => _MessageSheetState();
}

class _MessageSheetState extends State<MessageSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    if (_text.text.trim().isEmpty) return;
    if (context.read<SipPhone>().send(widget.peer, _text.text)) {
      _text.clear();
    } else {
      context.read<ShellCubit>().say('전화 서버에 연결되지 않아 문자를 못 보냈어요');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fb;
    final messages = context.select(
      (SipPhone p) => p.state.messages.where((m) => m.peer == widget.peer).toList(growable: false),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHead(title: '${widget.name}님과 문자'),
        if (messages.isEmpty) const EmptyText('아직 주고받은 문자가 없어요'),
        for (final m in messages)
          Align(
            alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 3.2),
              padding: const EdgeInsets.symmetric(horizontal: 13.6, vertical: 9.6),
              constraints: const BoxConstraints(maxWidth: 300),
              decoration: BoxDecoration(color: m.mine ? c.blueSoft : c.soft, borderRadius: BorderRadius.circular(16)),
              child: Text(m.text, style: FbText.body(c)),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(hintText: '보낼 문자를 입력하세요'),
              ),
            ),
            IconButton(tooltip: '보내기', onPressed: _send, icon: Icon(FbIcons.send, color: c.blue)),
          ],
        ),
      ],
    );
  }
}
