import Dependencies

// MARK: - Dependency Registration

private enum MediaLibraryClientKey: DependencyKey {
  static let liveValue: MediaLibraryClient = LiveMediaLibraryClient()
}

extension DependencyValues {
  var mediaLibrary: MediaLibraryClient {
    get { self[MediaLibraryClientKey.self] }
    set { self[MediaLibraryClientKey.self] = newValue }
  }
}
