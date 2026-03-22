import Dependencies

// MARK: - Dependency Registration

private enum MediaLibraryKey: DependencyKey {
  static let liveValue: MediaLibrary = LiveMediaLibrary()
}

extension DependencyValues {
  var mediaLibrary: MediaLibrary {
    get { self[MediaLibraryKey.self] }
    set { self[MediaLibraryKey.self] = newValue }
  }
}
