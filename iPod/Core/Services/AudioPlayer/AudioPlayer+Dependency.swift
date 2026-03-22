import Dependencies

// MARK: - Dependency Registration

private enum AudioPlayerKey: DependencyKey {
  static let liveValue: AudioPlayer = LiveAudioPlayer()
}

extension DependencyValues {
  var audioPlayer: AudioPlayer {
    get { self[AudioPlayerKey.self] }
    set { self[AudioPlayerKey.self] = newValue }
  }
}
