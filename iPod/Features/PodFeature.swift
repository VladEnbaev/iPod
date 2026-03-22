import ComposableArchitecture
import Foundation

// MARK: - Main App Feature

@Reducer
struct PodFeature {
  static let nowPlayingMenuID = UUID(uuidString: "3A12FB2D-E6B3-4D4A-92EB-3B4F5F0F1A4F")!
  
  // MARK: - State
  
  @ObservableState
  struct State: Equatable {
    var menuTree: MenuItemTree
    var player: PlayerFeature.State
    var isLoading: Bool = false
    var errorMessage: String?
    
    init() {
      let rootItem = MenuItem(
        title: "iPod",
        type: .folder,
        children: []
      )
      self.menuTree = .init(root: rootItem)
      self.player = .init()
    }
  }
  
  // MARK: - Action
  
  enum Action: Equatable {
    // Menu
    case initializeMenu
    case mediaLibraryLoaded([MenuItem])
    case mediaLibraryError(String)
    case menuItemSelected(UUID)
    
    // Wheel
    case wheelButtonPressed(WheelButtonType)
    case wheelScrolled(WheelScrollDirection)

    // Player
    case player(PlayerFeature.Action)
  }
  
  // MARK: - Dependencies
  
  @Dependency(\.mediaLibrary) var mediaLibraryService
  
  // MARK: - Reducer
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .initializeMenu:
        state.isLoading = true
        state.errorMessage = nil
        
        // Создаем корневой элемент
        let rootItem = MenuItem(
          title: "iPod",
          type: .folder,
          children: [
            MenuItem(title: "Playlists", type: .folder, children: []),
            MenuItem(title: "Artists", type: .folder, children: []),
            MenuItem(title: "Songs", type: .folder, children: []),
            MenuItem(title: "Settings", type: .settings, children: [])
          ]
        )
        state.menuTree = MenuItemTree(root: rootItem)
        
        // Начинаем загрузку медиатеки
        return .run { send in
          do {
            let songs = try await mediaLibraryService.fetchSongs()
            await send(.mediaLibraryLoaded(songs))
          } catch {
            await send(.mediaLibraryError(error.localizedDescription))
          }
        }
        
      case .mediaLibraryLoaded(let songs):
        state.isLoading = false
        populateMenuTree(with: songs, tree: &state.menuTree)
        return .none
        
      case .mediaLibraryError(let error):
        state.isLoading = false
        state.errorMessage = error
        return .none

      case .menuItemSelected(let id):
        guard let selected = state.menuTree.item(withId: id) else { return .none }
        guard selected.isPlayable else { return .none }

        let queue: [MenuItem]
        switch selected.type {
        case .playlist:
          queue = selected.children
        case .track:
          if let parent = state.menuTree.parent(of: selected.id) {
            queue = parent.children
          } else {
            queue = [selected]
          }
        default:
          queue = [selected]
        }

        return .send(.player(.playTrack(selected, queue: queue)))
        
      case .wheelButtonPressed(_):
        return .none
        
      case .wheelScrolled(_):
        return .none

      case .player:
        return .none
      }
    }
    
    Scope(state: \.player, action: \.player) {
      PlayerFeature()
    }
  }
  
  // MARK: - Private Methods
  
  private func populateMenuTree(with songs: [MenuItem], tree: inout MenuItemTree) {
    let rootChildren = tree.children(of: nil)
    
    if let songsFolder = rootChildren.first(where: { $0.title == "Songs" }) {
      tree.add(items: makeTrackCopies(from: sortLibrarySongs(songs)), toFolderId: songsFolder.id)
    }
    
    if let playlistsFolder = rootChildren.first(where: { $0.title == "Playlists" }) {
      let playlistItems = makeAlbumItems(from: songs)
      tree.add(items: playlistItems, toFolderId: playlistsFolder.id)
    }
    
    if let artistsFolder = rootChildren.first(where: { $0.title == "Artists" }) {
      let artistItems = makeArtistItems(from: songs)
      tree.add(items: artistItems, toFolderId: artistsFolder.id)
    }
  }

  private func makeAlbumItems(from songs: [MenuItem]) -> [MenuItem] {
    Dictionary(grouping: songs, by: albumLibraryKey(for:))
      .map { key, tracks in
        MenuItem(
          title: key.title,
          type: .album,
          children: makeTrackCopies(from: sortTracksWithinAlbum(tracks))
        )
      }
      .sorted(by: compareMenuItemsByTitle)
  }

  private func makeArtistItems(from songs: [MenuItem]) -> [MenuItem] {
    Dictionary(grouping: songs, by: artistName(for:))
      .map { artistName, artistSongs in
        let sortedAlbums = groupedAlbums(from: artistSongs)
        let allSongsItem = MenuItem(
          title: "All Songs",
          type: .folder,
          children: makeTrackCopies(
            from: sortedAlbums.flatMap(\.tracks)
          )
        )

        let albumItems = sortedAlbums.map { album in
          MenuItem(
            title: album.title,
            type: .album,
            children: makeTrackCopies(from: album.tracks)
          )
        }

        return MenuItem(
          title: artistName,
          type: .artist,
          children: [allSongsItem] + albumItems
        )
      }
      .sorted(by: compareMenuItemsByTitle)
  }

  private func groupedAlbums(from songs: [MenuItem]) -> [AlbumGroup] {
    Dictionary(grouping: songs, by: artistAlbumKey(for:))
      .map { key, tracks in
        AlbumGroup(
          title: key.title,
          year: key.year,
          tracks: sortTracksWithinAlbum(tracks)
        )
      }
      .sorted(by: compareAlbumGroups)
  }

  private func makeTrackCopies(from songs: [MenuItem]) -> [MenuItem] {
    songs.map { song in
      MenuItem(
        title: song.title,
        type: .track,
        metadata: song.metadata
      )
    }
  }

  private func sortLibrarySongs(_ songs: [MenuItem]) -> [MenuItem] {
    groupedLibraryAlbums(from: songs)
      .flatMap(\.tracks)
  }

  private func groupedLibraryAlbums(from songs: [MenuItem]) -> [LibraryAlbumGroup] {
    Dictionary(grouping: songs, by: albumLibraryKey(for:))
      .map { key, tracks in
        LibraryAlbumGroup(
          artist: key.artist,
          title: key.title,
          year: key.year,
          tracks: sortTracksWithinAlbum(tracks)
        )
      }
      .sorted(by: compareLibraryAlbumGroups)
  }

  private func sortTracksWithinAlbum(_ songs: [MenuItem]) -> [MenuItem] {
    songs.sorted { lhs, rhs in
      compareOptionalInts(lhs.metadata?.discNumber, rhs.metadata?.discNumber)
      ?? compareOptionalInts(lhs.metadata?.trackNumber, rhs.metadata?.trackNumber)
      ?? compareStrings(lhs.title, rhs.title)
      ?? compareStrings(
        lhs.metadata?.fileURL.absoluteString ?? "",
        rhs.metadata?.fileURL.absoluteString ?? ""
      )
      ?? false
    }
  }

  private func albumLibraryKey(for song: MenuItem) -> LibraryAlbumKey {
    LibraryAlbumKey(
      artist: artistName(for: song),
      title: albumTitle(for: song),
      year: song.metadata?.year
    )
  }

  private func artistAlbumKey(for song: MenuItem) -> ArtistAlbumKey {
    ArtistAlbumKey(
      title: albumTitle(for: song),
      year: song.metadata?.year
    )
  }

  private func artistName(for song: MenuItem) -> String {
    normalizedTitle(song.metadata?.artist, fallback: "Unknown Artist")
  }

  private func albumTitle(for song: MenuItem) -> String {
    normalizedTitle(song.metadata?.album, fallback: "Unknown Album")
  }

  private func normalizedTitle(_ value: String?, fallback: String) -> String {
    let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? fallback : trimmed
  }

  private func compareMenuItemsByTitle(_ lhs: MenuItem, _ rhs: MenuItem) -> Bool {
    compareStrings(lhs.title, rhs.title) ?? false
  }

  private func compareAlbumGroups(_ lhs: AlbumGroup, _ rhs: AlbumGroup) -> Bool {
    compareOptionalInts(lhs.year, rhs.year)
    ?? compareStrings(lhs.title, rhs.title)
    ?? false
  }

  private func compareLibraryAlbumGroups(_ lhs: LibraryAlbumGroup, _ rhs: LibraryAlbumGroup) -> Bool {
    compareStrings(lhs.artist, rhs.artist)
    ?? compareOptionalInts(lhs.year, rhs.year)
    ?? compareStrings(lhs.title, rhs.title)
    ?? false
  }

  private func compareOptionalInts(_ lhs: Int?, _ rhs: Int?) -> Bool? {
    switch (lhs, rhs) {
    case let (lhs?, rhs?) where lhs != rhs:
      return lhs < rhs
    case (.none, .some):
      return false
    case (.some, .none):
      return true
    default:
      return nil
    }
  }

  private func compareStrings(_ lhs: String, _ rhs: String) -> Bool? {
    let comparison = lhs.localizedCaseInsensitiveCompare(rhs)

    switch comparison {
    case .orderedAscending:
      return true
    case .orderedDescending:
      return false
    case .orderedSame:
      return nil
    }
  }
}

private extension PodFeature {
  struct LibraryAlbumKey: Hashable {
    let artist: String
    let title: String
    let year: Int?
  }

  struct ArtistAlbumKey: Hashable {
    let title: String
    let year: Int?
  }

  struct AlbumGroup {
    let title: String
    let year: Int?
    let tracks: [MenuItem]
  }

  struct LibraryAlbumGroup {
    let artist: String
    let title: String
    let year: Int?
    let tracks: [MenuItem]
  }
}
