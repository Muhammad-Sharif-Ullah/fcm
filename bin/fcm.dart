import 'package:fcm/fcm.dart' as fcm;

void main(List<String> arguments) {
  // fcm.FcmHandler.instance.createAccessToken();
  final String deviceToken =
      "e6v1Re0_Tbu_FN-mJXMSyX:APA91bFSy5mqkdFI_cy2gfESQKnl9Hp2aHH8J3l9AKR3Mg30hhOp20FkK8B-1XkBL7SPzTk1sg_nKGMOEW0ePbEvmFS9Iynzvsmf_FHxygkK5jt99DvgXEgA2Bu3Wu_4th7t-vyqPNka";

  fcm.FcmHandler.instance.sendOTP(deviceToken: deviceToken);
}
