import MediaPlayer

// MARK: - MediaLibraryError

enum MediaLibraryError: Error {
  case requestDenied
}

// MARK: - Media Library Client

protocol MediaLibraryClient {
  func fetchSongs() async throws(MediaLibraryError) -> [MenuItem]
}

// MARK: - Live Media Library Implementation

final class LiveMediaLibraryClient: MediaLibraryClient {
  
  // MARK: - Init
  
  init() { }
  
  // MARK: - Public Methods
  
  func fetchSongs() async throws(MediaLibraryError) -> [MenuItem] {
    guard await requestAuthorization() else {
      throw MediaLibraryError.requestDenied
    }
    
    let query = MPMediaQuery.songs()
    let items = query.items ?? []
    
    return items.compactMap { item in
      guard let url = item.assetURL else { return nil }
      return MenuItem(
        title: item.title ?? "Unknown",
        type: .track,
        metadata: TrackInfo(
          duration: item.playbackDuration,
          artist: item.artist,
          album: item.albumTitle,
          artwork: item.artwork?.image(at: CGSize(width: 100, height: 100))?.accessibilityIdentifier,
          trackNumber: item.albumTrackNumber > 0 ? item.albumTrackNumber : nil,
          year: item.releaseDate.flatMap {
            Calendar.current.dateComponents([.year], from: $0).year
          },
          fileURL: url
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
