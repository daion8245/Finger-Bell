import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sip_ua/sip_ua.dart';

/// 문자 한 통. [peer]는 상대 내선 (senior / child / guardian, 서버 문자는 fingerbell).
class ChatMessage {
  final String peer;
  final String text;
  final bool mine;

  const ChatMessage(this.peer, this.text, {required this.mine});
}

class PhoneState {
  /// 이 기기가 등록한 내선 (= 고른 사용자 Persona 이름).
  final String? me;

  /// Asterisk에 등록되어 전화·문자를 주고받을 수 있는지.
  final bool online;

  /// 지금 통화 (한 번에 하나).
  final Call? call;

  /// 상대가 받아 통화가 이어졌는지.
  final bool answered;

  /// 방금 끝난 통화의 안내 문구 (한 번만 보여 줍니다).
  final String? notice;

  final List<ChatMessage> messages;

  const PhoneState({
    this.me,
    this.online = false,
    this.call,
    this.answered = false,
    this.notice,
    this.messages = const [],
  });

  /// 통화 상대 내선.
  String? get peer => call?.remote_identity;

  /// 걸려 온 전화인지.
  bool get incoming => call?.direction == Direction.incoming;

  PhoneState copyWith({String? me, bool? online, bool? answered, List<ChatMessage>? messages}) => PhoneState(
    me: me ?? this.me,
    online: online ?? this.online,
    call: call,
    answered: answered ?? this.answered,
    messages: messages ?? this.messages,
  );
}

/// 가족 인터넷 전화기: sip_ua로 Asterisk에 내선 등록하고, 가족 내선끼리 전화(INVITE)·문자(MESSAGE)를 주고받습니다.
class SipPhone extends Cubit<PhoneState> implements SipUaHelperListener {
  /// Asterisk SIP over WebSocket 주소 (`ws://<PC IP>:8088/ws`).
  final Uri server;
  final String password;
  final SIPUAHelper _sip;

  /// 웹은 상대 목소리를 `<audio>`에 붙여야 들립니다 (앱은 자동으로 재생).
  RTCVideoRenderer? _webAudio;

  /// Asterisk pjsip.conf의 시연용 비밀번호와 같아야 합니다.
  static const defaultPassword = String.fromEnvironment('FINGERBELL_SIP_PASSWORD', defaultValue: 'fingerbell-demo');

  SipPhone(this.server, {this.password = defaultPassword, SIPUAHelper? sip})
    : _sip = sip ?? SIPUAHelper(),
      super(const PhoneState()) {
    _sip.addSipUaHelperListener(this);
  }

  /// 백엔드와 같은 PC의 Asterisk. `--dart-define=FINGERBELL_SIP_URL=ws://192.168.0.10:8088/ws`로 바꿉니다.
  static Uri serverFor(Uri api) {
    const defined = String.fromEnvironment('FINGERBELL_SIP_URL');
    if (defined.isNotEmpty) return Uri.parse(defined);
    // shortcut: 항상 ws(평문)입니다. https로 연 웹에서 쓰려면 Asterisk에 TLS(wss)를 켜고 FINGERBELL_SIP_URL을 주세요.
    return Uri(scheme: 'ws', host: api.host, port: 8088, path: '/ws');
  }

  String _uri(String user) => 'sip:$user@${server.host}';

  /// 이 기기를 [user] 내선으로 등록합니다. 사용자를 바꾸면 예전 내선은 등록을 풀고 새로 등록합니다.
  Future<void> register(String user) async {
    if (state.me == user) return;
    state.call?.hangup();
    emit(PhoneState(me: user, messages: state.messages));
    final settings = UaSettings()
      ..transportType = TransportType.WS
      ..webSocketUrl = server.toString()
      ..uri = _uri(user)
      ..authorizationUser = user
      ..password = password
      ..userAgent = 'FingerBell'
      ..register = true
      // 같은 Wi-Fi 안에서만 통화하므로 STUN 서버가 필요 없습니다.
      ..iceServers = const [];
    await _sip.start(settings);
  }

  /// [user]에게 음성 전화를 겁니다. 등록되지 않았거나 이미 통화 중이면 false.
  Future<bool> call(String user) async {
    if (!state.online || state.call != null) return false;
    return _sip.call(_uri(user), voiceOnly: true);
  }

  void answer() => state.call?.answer(_sip.buildCallOptions(true));

  void hangup() => state.call?.hangup();

  /// [user]에게 문자를 보냅니다. 등록되지 않았거나 빈 문자면 false.
  bool send(String user, String text) {
    final body = text.trim();
    if (!state.online || body.isEmpty) return false;
    _sip.sendMessage(_uri(user), body);
    emit(state.copyWith(messages: [...state.messages, ChatMessage(user, body, mine: true)]));
    return true;
  }

  @visibleForTesting
  void receive(String from, String text) {
    if (text.isEmpty) return;
    emit(state.copyWith(messages: [...state.messages, ChatMessage(from, text, mine: false)]));
  }

  @override
  void registrationStateChanged(RegistrationState s) =>
      emit(state.copyWith(online: s.state == RegistrationStateEnum.REGISTERED));

  @override
  void transportStateChanged(TransportState s) {
    // 연결이 끊기면 등록 해제 이벤트 없이 끊기므로 여기서 내립니다. 다시 붙으면 sip_ua가 재등록합니다.
    if (s.state == TransportStateEnum.DISCONNECTED) emit(state.copyWith(online: false));
  }

  @override
  void callStateChanged(Call call, CallState s) {
    final current = state.call;
    if (current != null && current.id != call.id) {
      if (s.state == CallStateEnum.CALL_INITIATION) call.hangup({'status_code': 486}); // 통화 중
      return;
    }
    switch (s.state) {
      case CallStateEnum.CALL_INITIATION:
        emit(PhoneState(me: state.me, online: state.online, call: call, messages: state.messages));
      case CallStateEnum.ACCEPTED || CallStateEnum.CONFIRMED:
        emit(state.copyWith(answered: true));
      case CallStateEnum.STREAM when s.originator == Originator.remote:
        _playOnWeb(s.stream);
      case CallStateEnum.ENDED || CallStateEnum.FAILED:
        _playOnWeb(null);
        emit(
          PhoneState(
            me: state.me,
            online: state.online,
            notice: endNotice(s.state, s.cause?.cause, s.originator, answered: state.answered, incoming: state.incoming),
            messages: state.messages,
          ),
        );
      default:
        break;
    }
  }

  /// 통화가 끝난 이유를 사람 말로.
  @visibleForTesting
  static String endNotice(
    CallStateEnum state,
    String? cause,
    Originator? by, {
    required bool answered,
    bool incoming = false,
  }) {
    if (answered || state == CallStateEnum.ENDED) return '통화를 마쳤어요';
    if (by == Originator.local) return cause == 'User Denied Media Access' ? '마이크를 쓸 수 있게 허용해 주세요' : '전화를 끊었어요';
    if (incoming) return '상대가 전화를 끊었어요';
    return switch (cause) {
      'Busy' => '상대가 통화 중이에요',
      'Rejected' || 'Canceled' || 'No Answer' => '상대가 전화를 받지 않았어요',
      _ => '상대가 연결되어 있지 않아요',
    };
  }

  Future<void> _playOnWeb(MediaStream? stream) async {
    if (!kIsWeb) return;
    if (_webAudio == null) {
      _webAudio = RTCVideoRenderer();
      await _webAudio!.initialize();
    }
    _webAudio!.srcObject = stream;
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    final from = msg.message?.remote_identity?.uri?.user;
    final Object? body = msg.request?.body;
    if (from != null && body is String) receive(from, body);
  }

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}

  @override
  Future<void> close() async {
    _sip.removeSipUaHelperListener(this);
    if (state.me != null) _sip.stop();
    await _webAudio?.dispose();
    return super.close();
  }
}
