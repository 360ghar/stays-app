import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/config/app_config.dart';

class AboutController extends GetxController {
  final RxString version = ''.obs;
  final RxString buildNumber = ''.obs;
  final RxString environment = ''.obs;

  final List<Map<String, String>> complianceItems = const [
    {'title': 'Terms & Conditions', 'route': Routes.legal, 'slug': 'terms'},
    {
      'title': 'Privacy Policy',
      'route': Routes.profilePrivacy,
      'slug': 'privacy-policy',
    },
    {
      'title': 'Refund & Cancellation Policy',
      'route': Routes.profileHelp,
      'slug': 'refunds',
    },
    {
      'title': 'Licenses & Compliance',
      'route': Routes.profileAbout,
      'slug': 'licenses',
    },
  ];

  @override
  void onInit() {
    super.onInit();
    environment.value = AppConfig.I.environment;
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      version.value = info.version;
      buildNumber.value = info.buildNumber;
    } catch (e, stack) {
      AppLogger.error('Unable to read package info', e, stack);
      version.value = '1.0.0';
      buildNumber.value = '1';
    }
  }
}
