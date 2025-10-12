import ComposableArchitecture
import Foundation

@Reducer
struct PodFeature {
  
  
  // MARK: - State
  
  @ObservableState
  struct State: Equatable {
    var menuTree: MenuItemTree
    var currentPath: [MenuItem] = []
    var selectedIndex: Int = 0
    var isPlaying: Bool = false
    var currentTrack: MenuItem
    
    var currentItems: [MenuItem] {
      if currentPath.isEmpty {
        return menuTree.root.children
      } else {
        return currentPath.last?.children ?? []
      }
    }
    
    var canGoBack: Bool {
      !currentPath.isEmpty
    }
    
    var canEnterSelected: Bool {
      let items = currentItems
      return selectedIndex < items.count && items[selectedIndex].hasChildren
    }
    
    init() {
      let tree = MenuItemTree.createDefaultTree()
      self.menuTree = tree
      self.currentTrack = tree.root
    }
  }
  
  // MARK: - Action
  
  enum Action: Equatable {
    case buttonPressed(WheelButtonType)
    case scrolled(WheelScrollDirection)
    case enterSelectedItem
    case goBack
    case playPause
    case selectItem(Int)
  }
  
  
  // MARK: - Reduce
  
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .buttonPressed(let button):
      switch button {
      case .menu:
        // Возврат в главное меню
        state.currentPath = []
        state.selectedIndex = 0
      case .next:
        break
//        // Переход к следующему элементу
//        if state.selectedIndex < state.currentItems.count - 1 {
//          state.selectedIndex += 1
//        }
      case .previous:
        break
//        // Переход к предыдущему элементу
//        if state.selectedIndex > 0 {
//          state.selectedIndex -= 1
//        }
      case .play:
        return .send(.playPause)
      case .center:
        return .send(.enterSelectedItem)
      }
      return .none
      
    case .scrolled(let direction):
      switch direction {
      case .left:
        // Скролл влево (предыдущий элемент)
        if state.selectedIndex > 0 {
          state.selectedIndex -= 1
        }
      case .right:
        // Скролл вправо (следующий элемент)
        if state.selectedIndex < state.currentItems.count - 1 {
          state.selectedIndex += 1
        }
      }
      return .none
      
    case .enterSelectedItem:
      let items = state.currentItems
      guard state.selectedIndex < items.count else { return .none }
      
      let selectedItem = items[state.selectedIndex]
      
      if selectedItem.hasChildren {
        // Вход в папку
        state.currentPath.append(selectedItem)
        state.selectedIndex = 0
      } else if selectedItem.isPlayable {
        // Воспроизведение трека/плейлиста
        state.currentTrack = selectedItem
        state.isPlaying = true
      }
      return .none
      
    case .goBack:
      guard state.canGoBack else { return .none }
      state.currentPath.removeLast()
      state.selectedIndex = 0
      return .none
      
    case .playPause:
      state.isPlaying.toggle()
      return .none
      
    case .selectItem(let index):
      guard index >= 0 && index < state.currentItems.count else { return .none }
      state.selectedIndex = index
      return .none
    }
  }
}
