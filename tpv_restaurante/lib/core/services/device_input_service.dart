import 'dart:io';
import 'package:flutter/services.dart';

class DeviceInputInfo {
  final bool isTouchDevice;
  final bool hasTouchScreen;
  final bool hasPhysicalKeyboard;
  final bool isTabletMode;

  const DeviceInputInfo({
    required this.isTouchDevice,
    required this.hasTouchScreen,
    required this.hasPhysicalKeyboard,
    required this.isTabletMode,
  });

  bool get shouldShowVirtualKeyboard => isTouchDevice && !hasPhysicalKeyboard;

  static const DeviceInputInfo defaultDesktop = DeviceInputInfo(
    isTouchDevice: false,
    hasTouchScreen: false,
    hasPhysicalKeyboard: true,
    isTabletMode: false,
  );
}

class DeviceInputService {
  static const MethodChannel _channel = MethodChannel(
    'tpv_restaurante/device_input',
  );

  Future<DeviceInputInfo> getDeviceInputInfo() async {
    if (!Platform.isWindows) {
      return DeviceInputInfo.defaultDesktop;
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getDeviceInputInfo',
      );

      if (result != null) {
        return DeviceInputInfo(
          isTouchDevice: result['isTouchDevice'] as bool? ?? false,
          hasTouchScreen: result['hasTouchScreen'] as bool? ?? false,
          hasPhysicalKeyboard: result['hasPhysicalKeyboard'] as bool? ?? true,
          isTabletMode: result['isTabletMode'] as bool? ?? false,
        );
      }
    } on PlatformException catch (e) {
      print('Error getting device input info: ${e.message}');
    } on MissingPluginException {
      print('Native method not implemented, using fallback detection');
    }

    return await _fallbackDetection();
  }

  Future<DeviceInputInfo> _fallbackDetection() async {
    bool isTouchDevice = false;
    bool hasTouchScreen = false;
    bool hasPhysicalKeyboard = true;
    bool isTabletMode = false;

    try {
      final touchResult = await Process.run('powershell', [
        '-Command',
        '''
        \$tablet = [System.Windows.Forms.SystemInformation]::TabletPC;
        \$touch = [System.Windows.Forms.SystemInformation]::Touch;
        \$tabletMode = (Get-ItemProperty -Path 'HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ImmersiveShell' -Name 'TabletMode' -ErrorAction SilentlyContinue).TabletMode;
        Write-Output "tablet:\$tablet;touch:\$touch;tabletMode:\$tabletMode"
        ''',
      ]);

      final output = touchResult.stdout.toString().toLowerCase();
      if (output.contains('tablet:true') || output.contains('touch:true')) {
        hasTouchScreen = true;
        isTouchDevice = true;
      }
      if (output.contains('tabletmode:1')) {
        isTabletMode = true;
      }
    } catch (e) {
      print('Fallback detection error: $e');
    }

    try {
      final keyboardResult = await Process.run('powershell', [
        '-Command',
        '''
        \$keyboards = Get-WmiObject -Class Win32_Keyboard | Where-Object { \$_.DeviceID -notmatch 'Virtual' -and \$_.DeviceID -notmatch 'HID' };
        if (\$keyboards) { Write-Output 'hasKeyboard' } else { Write-Output 'noKeyboard' }
        ''',
      ]);

      hasPhysicalKeyboard = keyboardResult.stdout.toString().contains(
        'hasKeyboard',
      );
    } catch (e) {
      print('Keyboard detection error: $e');
      hasPhysicalKeyboard = true;
    }

    return DeviceInputInfo(
      isTouchDevice: isTouchDevice,
      hasTouchScreen: hasTouchScreen,
      hasPhysicalKeyboard: hasPhysicalKeyboard,
      isTabletMode: isTabletMode,
    );
  }
}
