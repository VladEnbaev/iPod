import AVFoundation
import MediaPlayer
import UIKit

// MARK: - Audio Player Events

enum AudioPlayerRemoteCommand: Equatable {
  case play
  case pause
  case togglePlayPause
  case nextTrack
  case previousTrack
  case seek(TimeInterval)
}

enum AudioPlayerEvent: Equatable {
  /// Current time changed (seconds).
  case time(TimeInterval)
  /// Duration became known/changed (seconds).
  case duration(TimeInterval)
  /// Playback state changed.
  case playing(Bool)
  /// Current item finished playing.
  case ended
  /// Remote command from Control Center / lock screen.
  case remoteCommand(AudioPlayerRemoteCommand)
  /// Non-fatal error description.
  case error(String)
}

// MARK: - Audio Player Protocol

protocol AudioPlayer {
  /// Event stream that the feature can subscribe to.
  func events() -> AsyncStream<AudioPlayerEvent>

  // Loading / playback
  func load(track: MenuItem) async
  func play() async
  func pause() async
  func seek(to time: TimeInterval) async
  func setVolume(_ volume: Float) async

  // Session
  func setupAudioSession() async throws
  func setupRemoteCommands() async
  func updateNowPlayingInfo(
    track: MenuItem?,
    currentTime: TimeInterval,
    duration: TimeInterval,
    isPlaying: Bool
  ) async
}

// MARK: - Live Audio Player Implementation

final class LiveAudioPlayer: AudioPlayer {
  
  // MARK: - Parameters
  
  private var player: AVPlayer?
  private var playerItem: AVPlayerItem?
  private var timeObserver: Any?
  private var remoteCommandsConfigured: Bool = false
  private var remoteCommandBindings: [(command: MPRemoteCommand, token: Any)] = []

  private let eventStream: AsyncStream<AudioPlayerEvent>
  private var continuation: AsyncStream<AudioPlayerEvent>.Continuation?
  
  // MARK: - Init

  init() {
    var c: AsyncStream<AudioPlayerEvent>.Continuation?
    self.eventStream = AsyncStream<AudioPlayerEvent> { continuation in
      c = continuation
      continuation.onTermination = { _ in }
    }
    self.continuation = c
  }
  
  // MARK: - Deinit
  
  deinit {
    if let timeObserver = timeObserver {
      player?.removeTimeObserver(timeObserver)
    }
    cleanupRemoteCommands()
    NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: - Events

  func events() -> AsyncStream<AudioPlayerEvent> {
    eventStream
  }

  private func emit(_ event: AudioPlayerEvent) {
    continuation?.yield(event)
  }
  
  // MARK: - Loading
  
  func load(track: MenuItem) async {
    // Clean up observers from previous item
    if let timeObserver {
      await MainActor.run {
        player?.removeTimeObserver(timeObserver)
      }
      self.timeObserver = nil
    }

    if let playerItem {
      NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }

    guard let url = await getTrackURL(from: track) else {
      emit(.error("Track URL not found"))
      return
    }

    let item = AVPlayerItem(url: url)
    self.playerItem = item

    await MainActor.run {
      self.player = AVPlayer(playerItem: item)
    }

    // End of track
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak self] _ in
      self?.emit(.ended)
      self?.emit(.playing(false))
    }

    // Duration
    Task.detached { [weak self, weak item] in
      guard let self, let item else { return }
      do {
        let duration = try await item.asset.load(.duration)
        let seconds = duration.seconds
        if seconds.isFinite, seconds > 0 {
          self.emit(.duration(seconds))
        }
      } catch {
        self.emit(.error("Failed to load duration: \(error.localizedDescription)"))
      }
    }

    // Time observer
    await MainActor.run {
      guard let player = self.player else { return }
      let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
      self.timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
        guard let self else { return }
        let t = time.seconds
        if t.isFinite {
          self.emit(.time(t))
        }
      }
    }

    // Initial state
    emit(.time(0))
    emit(.playing(false))
  }
  
  private func getTrackURL(from track: MenuItem) async -> URL? {
    if let url = track.metadata?.fileURL {
      return url
    }

    // Fallback for demo builds: bundle audio if present.
    if let demoURL = Bundle.main.url(forResource: "demo", withExtension: "mp3") {
      return demoURL
    }

    print("Track URL not found (no metadata URL, demo asset missing)")
    return nil
  }
  
  // MARK: - Playback Control
  
  func play() async {
    await MainActor.run {
      player?.play()
    }
    emit(.playing(true))
  }
  
  func pause() async {
    await MainActor.run {
      player?.pause()
    }
    emit(.playing(false))
  }
  
  func seek(to time: TimeInterval) async {
    await MainActor.run {
      let cmTime = CMTime(seconds: time, preferredTimescale: 600)
      player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
  }
  
  func setVolume(_ volume: Float) async {
    await MainActor.run {
      player?.volume = volume
    }
  }
  
  // MARK: - Audio Session
  
  func setupAudioSession() async throws {
    try await MainActor.run {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(
        .playback,
        mode: .default,
        options: [.allowAirPlay, .allowBluetoothHFP, .mixWithOthers]
      )
      try audioSession.setActive(true)
    }
  }

  func setupRemoteCommands() async {
    await MainActor.run {
      guard !remoteCommandsConfigured else { return }

      let center = MPRemoteCommandCenter.shared()
      center.playCommand.isEnabled = true
      center.pauseCommand.isEnabled = true
      center.togglePlayPauseCommand.isEnabled = true
      center.nextTrackCommand.isEnabled = true
      center.previousTrackCommand.isEnabled = true
      center.changePlaybackPositionCommand.isEnabled = true

      let playToken = center.playCommand.addTarget { [weak self] _ in
        self?.emit(.remoteCommand(.play))
        return .success
      }
      let pauseToken = center.pauseCommand.addTarget { [weak self] _ in
        self?.emit(.remoteCommand(.pause))
        return .success
      }
      let toggleToken = center.togglePlayPauseCommand.addTarget { [weak self] _ in
        self?.emit(.remoteCommand(.togglePlayPause))
        return .success
      }
      let nextToken = center.nextTrackCommand.addTarget { [weak self] _ in
        self?.emit(.remoteCommand(.nextTrack))
        return .success
      }
      let previousToken = center.previousTrackCommand.addTarget { [weak self] _ in
        self?.emit(.remoteCommand(.previousTrack))
        return .success
      }
      let seekToken = center.changePlaybackPositionCommand.addTarget { [weak self] event in
        guard let event = event as? MPChangePlaybackPositionCommandEvent else {
          return .commandFailed
        }
        self?.emit(.remoteCommand(.seek(event.positionTime)))
        return .success
      }

      remoteCommandBindings = [
        (center.playCommand, playToken),
        (center.pauseCommand, pauseToken),
        (center.togglePlayPauseCommand, toggleToken),
        (center.nextTrackCommand, nextToken),
        (center.previousTrackCommand, previousToken),
        (center.changePlaybackPositionCommand, seekToken)
      ]
      remoteCommandsConfigured = true
    }
  }

  func updateNowPlayingInfo(
    track: MenuItem?,
    currentTime: TimeInterval,
    duration: TimeInterval,
    isPlaying: Bool
  ) async {
    await MainActor.run {
      guard let track else {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        return
      }

      var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
      nowPlayingInfo[MPMediaItemPropertyTitle] = track.title

      if let artist = track.metadata?.artist {
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
      } else {
        nowPlayingInfo.removeValue(forKey: MPMediaItemPropertyArtist)
      }

      if let album = track.metadata?.album {
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
      } else {
        nowPlayingInfo.removeValue(forKey: MPMediaItemPropertyAlbumTitle)
      }

      if let artwork = nowPlayingArtwork(from: track.metadata?.artwork) {
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
      } else {
        nowPlayingInfo.removeValue(forKey: MPMediaItemPropertyArtwork)
      }

      let resolvedDuration = duration > 0 ? duration : (track.metadata?.duration ?? 0)
      if resolvedDuration > 0 {
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = resolvedDuration
      } else {
        nowPlayingInfo.removeValue(forKey: MPMediaItemPropertyPlaybackDuration)
      }

      nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = max(0, currentTime)
      nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
      nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
  }

  private func nowPlayingArtwork(from data: Data?) -> MPMediaItemArtwork? {
    guard let data, let image = UIImage(data: data) else { return nil }

    return MPMediaItemArtwork(boundsSize: image.size) { _ in
      image
    }
  }

  private func cleanupRemoteCommands() {
    let cleanup = {
      guard self.remoteCommandsConfigured else { return }

      self.remoteCommandBindings.forEach { binding in
        binding.command.removeTarget(binding.token)
      }
      self.remoteCommandBindings.removeAll()
      self.remoteCommandsConfigured = false
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    if Thread.isMainThread {
      cleanup()
    } else {
      DispatchQueue.main.sync {
        cleanup()
      }
    }
  }
}

// MARK: - Notifications

extension Notification.Name {
  static let playbackInterrupted = Notification.Name("playbackInterrupted")
}
