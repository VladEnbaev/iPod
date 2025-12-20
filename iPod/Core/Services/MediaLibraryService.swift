import ComposableArchitecture
import MediaPlayer

// MARK: - MediaLibraryError

enum MediaLibraryError: Error {
  case requestDenied
}

// MARK: - MediaLibraryService

final class MediaLibraryService {
  
  // MARK: - Init
  
  init() { }
  
  // MARK: - Public Methods
  
  func fetchSongs() async throws(MediaLibraryError) -> [MenuItem] {
    guard await requestAuthorization() else {
      throw MediaLibraryError.requestDenied
    }
    
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
  
  // MARK: - Private Methods
  
  private func requestAuthorization() async -> Bool {
    await withCheckedContinuation { continuation in
      MPMediaLibrary.requestAuthorization { status in
        continuation.resume(returning: status == .authorized)
      }
    }
  }
}

// MARK: - Dependency

extension DependencyValues {
  var mediaLibraryService: MediaLibraryService {
    get { self[MediaLibraryServiceKey.self] }
    set { self[MediaLibraryServiceKey.self] = newValue }
  }
}

private enum MediaLibraryServiceKey: DependencyKey {
  static let liveValue: MediaLibraryService = .init()
}
