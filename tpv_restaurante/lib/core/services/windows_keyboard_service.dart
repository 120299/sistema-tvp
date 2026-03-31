import 'dart:io';

class WindowsKeyboardService {
  static Future<void> disableAllTouchKeyboard() async {
    if (!Platform.isWindows) return;

    try {
      await _killKeyboardProcesses();
      await _disableRegistryKeys();
    } catch (e) {
      // Silently fail
    }
  }

  static Future<void> _killKeyboardProcesses() async {
    final processes = [
      'osk.exe',
      'TabTip.exe',
      'TextInputHost.exe',
      'InputPersonalization.exe',
    ];

    for (final process in processes) {
      try {
        await Process.run('taskkill', ['/IM', process, '/F', '/T']);
      } catch (e) {
        // Process not found or access denied
      }
    }
  }

  static Future<void> _disableRegistryKeys() async {
    try {
      await Process.run('powershell', [
        '-Command',
        '''
        # Create registry keys if they don't exist
        \$tabletTipPath = 'HKCU:\\SOFTWARE\\Microsoft\\TabletTip'
        \$immersiveShellPath = 'HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ImmersiveShell'
        
        if (!(Test-Path \$tabletTipPath)) { New-Item -Path \$tabletTipPath -Force | Out-Null }
        if (!(Test-Path \$immersiveShellPath)) { New-Item -Path \$immersiveShellPath -Force | Out-Null }
        
        # Disable tablet input panel features
        Set-ItemProperty -Path \$tabletTipPath -Name 'EnableTipSticky' -Value 0 -Type DWord -Force
        Set-ItemProperty -Path \$tabletTipPath -Name 'TipBand' -Value 0 -Type DWord -Force
        Set-ItemProperty -Path \$tabletTipPath -Name 'Predictor' -Value 0 -Type DWord -Force
        Set-ItemProperty -Path \$tabletTipPath -Name 'Handwriting' -Value 0 -Type DWord -Force
        Set-ItemProperty -Path \$tabletTipPath -Name 'TouchInput' -Value 0 -Type DWord -Force
        Set-ItemProperty -Path \$tabletTipPath -Name 'EmbeddingAlignment' -Value 0 -Type DWord -Force
        Set-ItemProperty -Path \$tabletTipPath -Name 'LastActivationSource' -Value '' -Type String -Force
        
        # Disable tablet mode
        Set-ItemProperty -Path \$immersiveShellPath -Name 'TabletMode' -Value 0 -Type DWord -Force
        Set-ItemProperty -Path \$immersiveShellPath -Name 'ShowKeyboardEntryOnDesktop' -Value 0 -Type DWord -Force
        Set-ItemProperty -Path \$immersiveShellPath -Name 'UseDesktopOrientation' -Value 0 -Type DWord -Force
        Set-ItemProperty -Path \$immersiveShellPath -Name 'SigninAnimation' -Value 0 -Type DWord -Force
        
        # Disable suggestions
        \$pathsToDisable = @(
          'HKCU:\\SOFTWARE\\Microsoft\\Input\\TypingSuggestions',
          'HKCU:\\SOFTWARE\\Microsoft\\TabletTip\\TipBandPrediction'
        )
        
        foreach (\$p in \$pathsToDisable) {
          if (!(Test-Path \$p)) { New-Item -Path \$p -Force | Out-Null }
          Set-ItemProperty -Path \$p -Name 'Enabled' -Value 0 -Type DWord -Force
        }
        
        Write-Output 'disabled'
        ''',
      ]);
    } catch (e) {
      // Silently fail
    }
  }

  static Future<void> preventOskFromShowing() async {
    await disableAllTouchKeyboard();
  }

  static Future<void> enableTouchKeyboard() async {
    if (!Platform.isWindows) return;

    try {
      await Process.run('powershell', [
        '-Command',
        '''
        \$path = 'HKCU:\\SOFTWARE\\Microsoft\\TabletTip'
        if (Test-Path \$path) {
          Set-ItemProperty -Path \$path -Name 'EnableTipSticky' -Value 1 -Type DWord -Force
        }
        ''',
      ]);
    } catch (e) {
      // Silently fail
    }
  }
}
