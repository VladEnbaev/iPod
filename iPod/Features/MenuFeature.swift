import ComposableArchitecture

@Reducer
struct MenuFeature {
  
  
  // MARK: - State
  
  @ObservableState
  struct State: Equatable {
    var menuTree: MenuItemTree
    var pathIndices: [Int] = []
    var selectedIndex: Int = 0
    
    init() {
      menuTree = MenuItemTree.createDefaultTree()
    }
    
    var currentFolder: MenuItem {
      var item = menuTree.root
      for index in pathIndices {
        item = item.children[index]
      }
      return item
    }
    
    var canGoBack: Bool { !pathIndices.isEmpty }
    var canEnterSelected: Bool {
      currentFolder.children[selectedIndex].hasChildren
    }
  }
  
  
  // MARK: - Action
  
  enum Action: Equatable {
    case loadMediaLibrary
    case mediaLibraryLoaded([MenuItem])
    case mediaLibraryDenied
    case enterSelectedItem
    case scroll(MenuScrollDirection)
    case goBack
  }

  
  // MARK: - Dependencies
  
  @Dependency(\.mediaLibraryClient) var mediaLibraryClient
  
  
  // MARK: - Reducer
  
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .loadMediaLibrary:
      return .run { send in
        let granted = await mediaLibraryClient.requestAuthorization()
        guard granted else {
          await send(.mediaLibraryDenied)
          return
        }
        let songs = await mediaLibraryClient.fetchSongs()
        await send(.mediaLibraryLoaded(songs))
      }
      
    case .mediaLibraryLoaded(let songs):
      var root = state.menuTree.root
      if let index = root.children.firstIndex(where: { $0.title == "Songs" }) {
        root.children[index].children.append(contentsOf: songs)
      }
      state.menuTree = MenuItemTree(root: root)
      
      return .none
      
    case .mediaLibraryDenied:
      // Можно показать alert пользователю
      return .none
      
    case .enterSelectedItem:
      let selectedItem = state.currentFolder.children[state.selectedIndex]
      
      if selectedItem.hasChildren {
        state.pathIndices.append(state.selectedIndex)
        state.selectedIndex = 0
      }
      
      return .none
      
    case .scroll(let direction):
//      state.scrollDirection = direction
      switch direction {
      case .top:
        // Скролл влево (предыдущий элемент)
        if state.selectedIndex > 0 {
          state.selectedIndex -= 1
        }
      case .bottom:
        // Скролл вправо (следующий элемент)
        if state.selectedIndex < state.currentFolder.children.count - 1 {
          state.selectedIndex += 1
        }
      }
      return .none
      
    case .goBack:
      if state.canGoBack {
        state.selectedIndex = state.pathIndices.last ?? 0
        state.pathIndices.removeLast()
      }
      return .none
    }
  }
}
