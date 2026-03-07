import 'dart:io';

import 'package:nix/src/nix/wsl.dart';
import 'package:test/test.dart';

void main() {
  group('toWslPath', () {
    test('converts drive-letter paths to /mnt/', () {
      if (!Platform.isWindows) {
        markTestSkipped('toWslPath drive conversion only applies on Windows');
        return;
      }
      expect(toWslPath(r'C:\Users\alice\project'), '/mnt/c/Users/alice/project');
      expect(toWslPath(r'D:\builds\output'), '/mnt/d/builds/output');
      expect(
        toWslPath(r'C:\Users\alice\project\nix\flake.nix'),
        '/mnt/c/Users/alice/project/nix/flake.nix',
      );
    });

    test('handles forward-slash Windows paths', () {
      if (!Platform.isWindows) {
        markTestSkipped('toWslPath drive conversion only applies on Windows');
        return;
      }
      expect(toWslPath('C:/Users/alice'), '/mnt/c/Users/alice');
    });

    test('passes through unix paths unchanged on non-Windows', () {
      if (Platform.isWindows) {
        markTestSkipped('This test validates non-Windows passthrough');
        return;
      }
      expect(toWslPath('/home/alice/project'), '/home/alice/project');
      expect(toWslPath('./nix/flake.nix'), './nix/flake.nix');
    });
  });

  group('toWindowsPath', () {
    test('converts /mnt/ paths to drive letters', () {
      expect(toWindowsPath('/mnt/c/Users/alice'), r'C:\Users\alice');
      expect(toWindowsPath('/mnt/d/builds'), r'D:\builds');
    });

    test('passes through non-mount paths unchanged', () {
      expect(toWindowsPath('/home/alice'), '/home/alice');
      expect(toWindowsPath('./relative'), './relative');
    });
  });

  group('needsWsl', () {
    test('reflects platform', () {
      expect(needsWsl, Platform.isWindows);
    });
  });
}
