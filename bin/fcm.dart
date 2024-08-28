import 'package:fcm/fcm.dart' as fcm;

void main(List<String> arguments) {
  // fcm.FcmHandler.instance.createAccessToken();
  final String deviceToken =
      "cNGXU81nSG6AMb8YYj1Ny4:APA91bGZpAgw_gp6bl6kfgN4wIxCZLROt1duQiv-B43X5ggev1OBFuG59r6UpLOwvWm5ubq27DM5ehPq5-Ykhvf3VbpiMGZk6wae25oG1mqVMw-5Bhv5Xo14DJ3_SaR2V1DhLVowMou9";

  fcm.FcmHandler.instance.sendOTP();
}
