import 'package:ota_update/ota_update.dart';

class UpdateService {
  static void startOtaUpdate(String apkUrl) async {
    try {
      OtaUpdate()
          .execute(apkUrl, destinationFilename: 'carbex_latest.apk')
          .listen(
        (OtaEvent event) {
          print('OTA status: ${event.status} : ${event.value}');
        },
      );
    } catch (e) {
      print('Erreur OTA: $e');
    }
  }
}
