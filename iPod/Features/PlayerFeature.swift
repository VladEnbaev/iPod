import AVFoundation
import ComposableArchitecture

// MARK: - Player Feature

@Reducer
struct PlayerFeature {

  // MARK: State

  @ObservableState
  struct State: Equatable {
    var currentTrack: MenuItem?

    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var volume: Float = 0.7

    var shuffleMode: Bool = false
    var repeatMode: RepeatMode = .none
    var isObserving: Bool = false

    /// Current play queue (e.g. songs in the current folder/playlist)
    var queue: [MenuItem] = []
    /// Index of `currentTrack` in `queue` (if applicable)
    var currentQueueIndex: Int = 0

    enum RepeatMode: Equatable {
      case none, one, all

      mutating func cycle() {
        switch self {
        case .none: self = .one
        case .one: self = .all
        case .all: self = .none
        }
      }
    }

    // MARK: Derived UI state

    var progress: Double {
      guard duration > 0 else { return 0 }
      return min(1, max(0, currentTime / duration))
    }

    var timeRemaining: TimeInterval {
      max(0, duration - currentTime)
    }

    var timeElapsedString: String {
      Self.formatTime(currentTime)
    }

    var timeRemainingString: String {
      "-" + Self.formatTime(timeRemaining)
    }

    private static func formatTime(_ time: TimeInterval) -> String {
      let clamped = max(0, time)
      let minutes = Int(clamped) / 60
      let seconds = Int(clamped) % 60
      return String(format: "%d:%02d", minutes, seconds)
    }
  }

  // MARK: Action

  enum Action: Equatable {
    // Queue / navigation
    case playTrack(MenuItem, queue: [MenuItem]?)
    case nextTrack
    case previousTrack

    // Playback control
    case togglePlayPause
    case play
    case pause
    case seekToProgress(Double)
    case seekToTime(TimeInterval)

    // Player events
    case startObserving
    case stopObserving
    case playerEvent(AudioPlayerEvent)

    // Playback reporting
    case updateCurrentTime(TimeInterval)
    case trackEnded

    // Volume and settings
    case setVolume(Float)
    case toggleShuffle
    case changeRepeatMode

    // Internal
    case _setupAudioSession
    case _setupRemoteCommands
    case _updateNowPlayingInfo
  }

  // MARK: Dependencies

  @Dependency(\.audioPlayer) var audioPlayer

  // MARK: Cancellation

  private enum CancelID: Hashable {
    case playerEvents
  }

  // MARK: Reducer

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {

      // MARK: Queue

      // MARK: Load & play a concrete track

      case let .playTrack(track, queue):
        if let queue {
          state.queue = queue
          if let idx = queue.firstIndex(where: { $0.id == track.id }) {
            state.currentQueueIndex = idx
          } else {
            state.currentQueueIndex = 0
          }
        }
        // If track is in queue — align index.
        if let idx = state.queue.firstIndex(where: { $0.id == track.id }) {
          state.currentQueueIndex = idx
        }

        state.currentTrack = track
        state.duration = track.metadata?.duration ?? 0
        state.currentTime = 0

        // Start playing immediately.
        return .concatenate(
          .send(.startObserving),
          .send(._setupAudioSession),
          .send(._setupRemoteCommands),
          .send(._updateNowPlayingInfo),
          .run { [track, volume = state.volume] send in
            // NOTE: adapt these calls to your AudioPlayerClient.
            // The important part is: load -> volume -> play.
            await audioPlayer.load(track: track)
            await audioPlayer.setVolume(volume)
            await send(.play)
          }
        )

      // MARK: Play / pause

      case .togglePlayPause:
        return state.isPlaying ? .send(.pause) : .send(.play)

      case .play:
        guard state.currentTrack != nil else { return .none }
        state.isPlaying = true

        return .run { _ in
          await audioPlayer.play()
        }

      case .pause:
        state.isPlaying = false
        return .run { _ in
          await audioPlayer.pause()
        }

      // MARK: Seeking

      case let .seekToProgress(progress):
        let p = min(1, max(0, progress))
        let newTime = p * state.duration
        return .send(.seekToTime(newTime))

      case let .seekToTime(time):
        let clamped = min(max(0, time), state.duration > 0 ? state.duration : time)
        state.currentTime = clamped

        return .merge(
          .send(._updateNowPlayingInfo),
          .run { [time = clamped] _ in
            await audioPlayer.seek(to: time)
          }
        )

      // MARK: Player events observing

      case .startObserving:
        guard !state.isObserving else { return .none }
        state.isObserving = true
        return .run { send in
          for await event in audioPlayer.events() {
            await send(.playerEvent(event))
          }
        }
        .cancellable(id: CancelID.playerEvents)

      case .stopObserving:
        state.isObserving = false
        return .cancel(id: CancelID.playerEvents)

      case let .playerEvent(event):
        switch event {
        case let .time(t):
          state.currentTime = t
          return .send(._updateNowPlayingInfo)

        case let .duration(d):
          state.duration = d
          return .send(._updateNowPlayingInfo)

        case let .playing(isPlaying):
          state.isPlaying = isPlaying
          return .send(._updateNowPlayingInfo)

        case .ended:
          return .send(.trackEnded)

        case let .remoteCommand(command):
          switch command {
          case .play:
            return .send(.play)
          case .pause:
            return .send(.pause)
          case .togglePlayPause:
            return .send(.togglePlayPause)
          case .nextTrack:
            return .send(.nextTrack)
          case .previousTrack:
            return .send(.previousTrack)
          case let .seek(time):
            return .send(.seekToTime(time))
          }

        case let .error(message):
          // You can surface it in UI later.
          print("AudioPlayer error: \(message)")
          return .none
        }

      // MARK: Playback reporting

      case let .updateCurrentTime(time):
        state.currentTime = min(max(0, time), state.duration > 0 ? state.duration : time)
        return .send(._updateNowPlayingInfo)

      case .trackEnded:
        switch state.repeatMode {
        case .one:
          // Repeat current.
          return .concatenate(
            .send(.seekToTime(0)),
            .send(.play)
          )

        case .none:
          // If there is a next track — go there, otherwise stop.
          if let next = nextIndex(state: state) {
            state.currentQueueIndex = next
            let track = state.queue[next]
            return .send(.playTrack(track, queue: nil))
          } else {
            return .send(.pause)
          }

        case .all:
          // Always advance (wrap around).
          if !state.queue.isEmpty {
            let next = nextIndexWrapping(state: state)
            state.currentQueueIndex = next
            let track = state.queue[next]
            return .send(.playTrack(track, queue: nil))
          } else {
            return .send(.pause)
          }
        }

      // MARK: Next / previous

      case .nextTrack:
        guard !state.queue.isEmpty else { return .none }

        let next: Int
        if state.shuffleMode {
          next = randomIndex(excluding: state.currentQueueIndex, count: state.queue.count)
        } else {
          next = nextIndexWrapping(state: state)
        }

        state.currentQueueIndex = next
        return .send(.playTrack(state.queue[next], queue: nil))

      case .previousTrack:
        guard !state.queue.isEmpty else { return .none }

        // iPod-like UX: if user already listened > 3 seconds — restart track; otherwise go to previous.
        if state.currentTime > 3 {
          return .send(.seekToTime(0))
        }

        let prevIndex = (state.currentQueueIndex - 1 + state.queue.count) % state.queue.count
        state.currentQueueIndex = prevIndex
        return .send(.playTrack(state.queue[prevIndex], queue: nil))

      // MARK: Settings

      case let .setVolume(volume):
        state.volume = min(1, max(0, volume))
        return .run { [v = state.volume] _ in
          await audioPlayer.setVolume(v)
        }

      case .toggleShuffle:
        state.shuffleMode.toggle()
        return .none

      case .changeRepeatMode:
        state.repeatMode.cycle()
        return .none

      // MARK: Internals

      case ._setupAudioSession:
        return .run { _ in
          try await audioPlayer.setupAudioSession()
        } catch: { _, error in
          // Avoid crashing on setup errors (e.g. simulator / missing audio route).
          print("Audio session setup error: \(error)")
        }

      case ._setupRemoteCommands:
        return .run { _ in
          await audioPlayer.setupRemoteCommands()
        }

      case ._updateNowPlayingInfo:
        return .run {
          [
            track = state.currentTrack,
            currentTime = state.currentTime,
            duration = state.duration,
            isPlaying = state.isPlaying
          ] _ in
          await audioPlayer.updateNowPlayingInfo(
            track: track,
            currentTime: currentTime,
            duration: duration,
            isPlaying: isPlaying
          )
        }
      }
    }
  }

  // MARK: Helpers

  private func nextIndex(state: State) -> Int? {
    guard !state.queue.isEmpty else { return nil }

    if state.shuffleMode {
      return randomIndex(excluding: state.currentQueueIndex, count: state.queue.count)
    }

    let candidate = state.currentQueueIndex + 1
    return candidate < state.queue.count ? candidate : nil
  }

  private func nextIndexWrapping(state: State) -> Int {
    guard !state.queue.isEmpty else { return 0 }

    if state.shuffleMode {
      return randomIndex(excluding: state.currentQueueIndex, count: state.queue.count)
    }

    return (state.currentQueueIndex + 1) % state.queue.count
  }

  private func randomIndex(excluding excluded: Int, count: Int) -> Int {
    guard count > 1 else { return 0 }

    var idx = Int.random(in: 0..<count)
    while idx == excluded {
      idx = Int.random(in: 0..<count)
    }
    return idx
  }
}
