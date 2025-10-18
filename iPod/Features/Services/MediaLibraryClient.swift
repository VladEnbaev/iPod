import ComposableArchitecture
import MediaPlayer

struct MediaLibraryClient {
  var requestAuthorization: @Sendable () async -> Bool
  var fetchSongs: @Sendable () async -> [MenuItem]
}

extension DependencyValues {
  var mediaLibraryClient: MediaLibraryClient {
    get { self[MediaLibraryClientKey.self] }
    set { self[MediaLibraryClientKey.self] = newValue }
  }
}

private enum MediaLibraryClientKey: DependencyKey {
  static let liveValue: MediaLibraryClient = .live
}

extension MediaLibraryClient {
  static let live = MediaLibraryClient(
    requestAuthorization: {
      await withCheckedContinuation { continuation in
        MPMediaLibrary.requestAuthorization { status in
          continuation.resume(returning: status == .authorized)
        }
      }
    },
    fetchSongs: {
      let query = MPMediaQuery.songs()
      let items = query.items ?? []
      
      return items.map { item in
        MenuItem(
          title: item.title ?? "Unknown",
          type: .track,
          metadata: MenuItemMetadata(
            duration: item.playbackDuration,
            artist: item.artist,
            album: item.albumTitle,
            artwork: item.artwork?.image(at: CGSize(width: 100, height: 100))?.accessibilityIdentifier,
            trackNumber: item.albumTrackNumber,
            year: item.releaseDate.flatMap {
              Calendar.current.dateComponents([.year], from: $0).year
            }
          )
        )
      }
    }
  )
}
