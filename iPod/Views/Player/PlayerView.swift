import SwiftUI
import ComposableArchitecture

// MARK: - PlayerView

struct PlayerView: View {

  // MARK: - Properties

  let store: StoreOf<PlayerFeature>

  // MARK: - Init

  init(store: StoreOf<PlayerFeature>) {
    self.store = store
  }

  // MARK: - Body

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: .zero) {
        header
          .padding(.bottom, 8)

        trackInfo
          .padding(.bottom, 16)

        PlayerProgressView(
          progress: store.progress,
          timeElapsed: store.timeElapsedString,
          timeRemaining: store.timeRemainingString
        )
      }
      .padding(10)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(Color.Pod.displayWhite)
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
