import 'package:feature_call/feature_call.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sip_ua/sip_ua.dart';

void main() {
  test('Asterisk address follows the backend host', () {
    expect(SipPhone.serverFor(Uri.parse('http://192.168.0.10:8765')).toString(), 'ws://192.168.0.10:8088/ws');
  });

  test('cannot call or text before registering, but keeps received texts', () async {
    final phone = SipPhone(Uri.parse('ws://127.0.0.1:8088/ws'));
    expect(await phone.call('guardian'), isFalse);
    expect(phone.send('guardian', '안녕'), isFalse);

    phone.receive('guardian', '밥 먹었어요?');
    expect(phone.state.messages.single.peer, 'guardian');
    expect(phone.state.messages.single.mine, isFalse);
    await phone.close();
  });

  test('end notice explains why a call ended', () {
    expect(SipPhone.endNotice(CallStateEnum.ENDED, 'BYE', Originator.remote, answered: true), '통화를 마쳤어요');
    expect(SipPhone.endNotice(CallStateEnum.FAILED, 'Busy', Originator.remote, answered: false), '상대가 통화 중이에요');
    expect(SipPhone.endNotice(CallStateEnum.FAILED, 'Unavailable', Originator.remote, answered: false), '상대가 연결되어 있지 않아요');
    expect(
      SipPhone.endNotice(CallStateEnum.FAILED, 'User Denied Media Access', Originator.local, answered: false),
      '마이크를 쓸 수 있게 허용해 주세요',
    );
    expect(
      SipPhone.endNotice(CallStateEnum.FAILED, 'Canceled', Originator.remote, answered: false, incoming: true),
      '상대가 전화를 끊었어요',
    );
  });
}
