import SwiftUI
import ComposableArchitecture

// MARK: - PlayerView

struct PlayerView: View {

  private static let volumeStep: Float = 0.05
  private static let volumeOverlayDuration: TimeInterval = 1.2

  // MARK: - Properties

  let store: StoreOf<PlayerFeature>
  let isActive: Bool

  @State private var showsVolumeView = false
  @State private var hideVolumeTask: Task<Void, Never>?

  // MARK: - Init

  init(store: StoreOf<PlayerFeature>, isActive: Bool = true) {
    self.store = store
    self.isActive = isActive
  }

  // MARK: - Body

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: .zero) {
        header
          .padding(.bottom, 8)

        trackInfo
          .padding(.bottom, 24)

        footer
      }
      .padding(10)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(Color.Pod.displayWhite)
      .onReceive(ScrollWheelEventsPublisher.shared.events) { event in
        guard isActive else { return }

        switch event {
        case let .scrolled(direction):
          let currentVolume = store.volume
          showVolumeView()
          adjustVolume(currentVolume: currentVolume, direction: direction)
        default:
          break
        }
      }
      .onDisappear {
        hideVolumeTask?.cancel()
        hideVolumeTask = nil
        showsVolumeView = false
      }
    }
  }

  // MARK: - Subviews

  private var header: some View {
    WithPerceptionTracking {
      HStack {
        Text("\(store.currentQueueIndex + 1) of \(max(store.queue.count, 1))")
          .font(.chicagoRegular(size: 20))
          .foregroundStyle(Color.Pod.displayBlack)

        Spacer()

        // Shuffle, etg
      }
    }
  }

  private var trackInfo: some View {
    WithPerceptionTracking {
      VStack(spacing: 4) {
        Text(store.currentTrack?.title ?? "—")
          .lineLimit(1)
          .font(.chicagoRegular(size: 24))
          .foregroundStyle(Color.Pod.displayBlack)
        
        Text(store.currentTrack?.metadata?.artist ?? "")
          .lineLimit(1)
          .font(.chicagoRegular(size: 24))
          .foregroundStyle(Color.Pod.displayBlack)
        
        Text(store.currentTrack?.metadata?.album ?? "")
          .lineLimit(1)
          .font(.chicagoRegular(size: 24))
          .foregroundStyle(Color.Pod.displayBlack)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
  
  @ViewBuilder
  private var footer: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      
      WithPerceptionTracking {
        ZStack {
          PlayerProgressView(
            progress: store.progress,
            timeRemaining: store.timeRemainingString
          )
          .offset(x: showsVolumeView ? -width : 0)
          .opacity(showsVolumeView ? 0 : 1)
          
          PlayerVolumeView(volume: Double(store.volume))
            .offset(x: showsVolumeView ? 0 : width)
            .opacity(showsVolumeView ? 1 : 0)
        }
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
        .animation(.smooth(duration: 0.2), value: showsVolumeView)
      }
    }
    .frame(height: 20, alignment: .center)
  }

  private func adjustVolume(currentVolume: Float, direction: WheelScrollDirection) {
    let delta = direction == .right ? Self.volumeStep : -Self.volumeStep
    let volume = min(1, max(0, currentVolume + delta))
    store.send(.setVolume(volume))
  }

  private func showVolumeView() {
    showsVolumeView = true

    hideVolumeTask?.cancel()
    hideVolumeTask = Task { @MainActor in
      let delay = UInt64(Self.volumeOverlayDuration * 1_000_000_000)
      try? await Task.sleep(nanoseconds: delay)

      guard !Task.isCancelled else { return }

      showsVolumeView = false
    }
  }

}

#Preview {
  PlayerView(
    store: .init(
      initialState: PlayerFeature.State(
        currentTrack: MenuItem(title: "Could You Be Loved", type: .track, metadata: TrackInfo(duration: 210, artist: "Bob Marley", album: "Legend", artwork: nil, trackNumber: 1, year: 1984, fileURL: URL(fileURLWithPath: "/dev/null"))),
        isPlaying: true,
        currentTime: 42,
        duration: 210,
        volume: 0.7,
        shuffleMode: false,
        repeatMode: .none,
        queue: [
          MenuItem(title: "Could You Be Loved", type: .track, metadata: TrackInfo(duration: 210, artist: "Bob Marley", album: "Legend", artwork: nil, trackNumber: 1, year: 1984, fileURL: URL(fileURLWithPath: "/dev/null"))),
          MenuItem(title: "Three Little Birds", type: .track, metadata: TrackInfo(duration: 180, artist: "Bob Marley", album: "Exodus", artwork: nil, trackNumber: 2, year: 1977, fileURL: URL(fileURLWithPath: "/dev/null")))
        ],
        currentQueueIndex: 0
      )
    ) {
      PlayerFeature()
    }
  )
}
