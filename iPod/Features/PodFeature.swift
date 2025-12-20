import ComposableArchitecture
import Foundation

// MARK: - Main App Feature

@Reducer
struct PodFeature {
  
  // MARK: - State
  
  @ObservableState
  struct State: Equatable {
    var menuTree: MenuItemTree
    var isLoading: Bool = false
    var errorMessage: String?
    
    init() {
      let rootItem = MenuItem(
        title: "iPod",
        type: .folder,
        children: []
      )
      self.menuTree = .init(root: rootItem)
    }
  }
  
  // MARK: - Action
  
  enum Action: Equatable {
    // Menu
    case initializeMenu
    case mediaLibraryLoaded([MenuItem])
    case mediaLibraryError(String)
    
    // Wheel
    case wheelButtonPressed(WheelButtonType)
    case wheelScrolled(WheelScrollDirection)
  }
  
  // MARK: - Dependencies
  
  @Dependency(\.mediaLibraryService) var mediaLibraryService
  
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
        
      case .wheelButtonPressed(_):
        return .none
        
      case .wheelScrolled(_):
        return .none
      }
    }
  }
  
  // MARK: - Private Methods
  
  private func populateMenuTree(with songs: [MenuItem], tree: inout MenuItemTree) {
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
    
    // Находим папки по названиям
    let rootChildren = tree.children(of: nil)
    
    if let songsFolder = rootChildren.first(where: { $0.title == "Songs" }) {
      tree.add(items: songs, toFolderId: songsFolder.id)
    }
    
    if let playlistsFolder = rootChildren.first(where: { $0.title == "Playlists" }) {
      let playlistItems = playlists.map { name, tracks in
        MenuItem(title: name, type: .playlist, children: tracks)
      }
      tree.add(items: playlistItems, toFolderId: playlistsFolder.id)
    }
    
    if let artistsFolder = rootChildren.first(where: { $0.title == "Artists" }) {
      let artistItems = artists.map { name, tracks in
        MenuItem(title: name, type: .artist, children: tracks)
      }
      tree.add(items: artistItems, toFolderId: artistsFolder.id)
    }
  }
}
