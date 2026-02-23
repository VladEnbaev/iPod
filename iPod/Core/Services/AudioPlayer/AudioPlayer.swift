import AVFoundation
import MediaPlayer

// MARK: - Audio Player Events

enum AudioPlayerEvent: Equatable {
  /// Current time changed (seconds).
  case time(TimeInterval)
  /// Duration became known/changed (seconds).
  case duration(TimeInterval)
  /// Playback state changed.
  case playing(Bool)
  /// Current item finished playing.
  case ended
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
}

// MARK: - Live Audio Player Implementation

final class LiveAudioPlayer: AudioPlayer {
  
  // MARK: - Parameters
  
  private var player: AVPlayer?
  private var playerItem: AVPlayerItem?
  private var timeObserver: Any?

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
        options: [.allowAirPlay, .allowBluetooth, .mixWithOthers]
      )
      try audioSession.setActive(true)
    }
  }
}

// MARK: - Notifications

extension Notification.Name {
  static let playbackInterrupted = Notification.Name("playbackInterrupted")
}
