import Foundation
import MediaPlayer
import ComposableArchitecture

// MARK: - MenuService

public final class MenuService {
  
  // MARK: - Parameters
  
  private var tree: MenuItemTree!
  private let mediaLibraryService: MediaLibraryService
  
  // MARK: - Init
  
  init(mediaLibraryService: MediaLibraryService = .init()) {
    self.mediaLibraryService = mediaLibraryService
    self.tree = createDefaultInterface()
  }
}

// MARK: - Public Methods
  
public extension MenuService {
  
  func root() -> MenuItem {
    tree.rootItem()
  }
  
  func item(withId id: UUID) -> MenuItem? {
    tree.item(withId: id)
  }
  
  func children(of id: UUID?) -> [MenuItem] {
    tree.children(of: id)
  }
  
  func parent(of id: UUID) -> MenuItem? {
    tree.parent(of: id)
  }
  
  func add(items: [MenuItem], toFolderId id: UUID?) {
    tree.add(items: items, toFolderId: id)
  }
  
  func loadMediaLibrary() async throws {
    let songs = try await mediaLibraryService.fetchSongs()
    fillMediaFolders(with: songs)
  }
}

// MARK: - Private Methods

private extension MenuService {
  
  private func createDefaultInterface() -> MenuItemTree {
    let root = MenuItem(
      title: "iPod",
      type: .folder,
      children: [
        MenuItem(
          title: "Playlists",
          type: .folder,
          children: []
        ),
        MenuItem(
          title: "Artists",
          type: .folder,
          children: []
        ),
        MenuItem(
          title: "Songs",
          type: .folder,
          children: []
        ),
        MenuItem(
          title: "Settings",
          type: .settings
        ),
      ]
    )
    
    return MenuItemTree(root: root)
  }
  
  private func fillMediaFolders(with songs: [MenuItem]) {
    var playlists: [String: [MenuItem]] = [:]
    var artists: [String: [MenuItem]] = [:]
    
    for song in songs {
      if let playlistName = song.metadata?.album {
        playlists[playlistName, default: []].append(song)
      }
      if let artistName = song.metadata?.artist {
        artists[artistName, default: []].append(song)
      }
    }
    
    // Добавляем Songs
    if let songsFolder = tree.children(of: nil).first(where: { $0.title == "Songs" }) {
      tree.add(items: songs, toFolderId: songsFolder.id)
    }
    
    // Добавляем Playlists
    let playlistItems = playlists.map { name, tracks in
      MenuItem(title: name, type: .playlist, children: tracks)
    }
    if let playlistsFolder = tree.children(of: nil).first(where: { $0.title == "Playlists" }) {
      tree.add(items: playlistItems, toFolderId: playlistsFolder.id)
    }
    
    // Добавляем Artists
    let artistItems = artists.map { name, tracks in
      MenuItem(title: name, type: .artist, children: tracks)
    }
    if let artistsFolder = tree.children(of: nil).first(where: { $0.title == "Artists" }) {
      tree.add(items: artistItems, toFolderId: artistsFolder.id)
    }
  }
}

// MARK: - Dependency

extension DependencyValues {
  var menuService: MenuService {
    get { self[MenuServiceKey.self] }
    set { self[MenuServiceKey.self] = newValue }
  }
}

private enum MenuServiceKey: DependencyKey {
  static let liveValue: MenuService = .init()
}
