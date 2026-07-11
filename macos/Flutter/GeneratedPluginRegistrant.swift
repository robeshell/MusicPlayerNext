//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import audio_session
import file_selector_macos
import just_audio
import media_kit_libs_macos_audio

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  AudioSessionPlugin.register(with: registry.registrar(forPlugin: "AudioSessionPlugin"))
  FileSelectorPlugin.register(with: registry.registrar(forPlugin: "FileSelectorPlugin"))
  JustAudioPlugin.register(with: registry.registrar(forPlugin: "JustAudioPlugin"))
  MediaKitLibsMacosAudioPlugin.register(with: registry.registrar(forPlugin: "MediaKitLibsMacosAudioPlugin"))
}
