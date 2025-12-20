import ComposableArchitecture
import Foundation

// MARK: - Menu Feature

@Reducer
struct MenuFeature {
  
  // MARK: - State
  
  @ObservableState
  struct State: Equatable {
    // Текущий элемент и история навигации
    var currentItem: MenuItem
    var navigationPath: [MenuItem] = []
    
    // Выбранный индекс в текущем списке
    var selectedIndex: Int = 0
    
    // Состояние загрузки
    var isLoading: Bool = false
    var errorMessage: String?
    
    // Вычисляемые свойства
    var canGoBack: Bool {
      !navigationPath.isEmpty
    }
    
    var currentItems: [MenuItem] {
      currentItem.children
    }
    
    var selectedItem: MenuItem? {
      guard !currentItems.isEmpty else { return nil }
      guard selectedIndex >= 0 && selectedIndex < currentItems.count else { return nil }
      return currentItems[selectedIndex]
    }
    
    var title: String {
      currentItem.title
    }
    
    init(rootItem: MenuItem) {
      self.currentItem = rootItem
    }
  }
  
  // MARK: - Action
  
  enum Action: Equatable {
    // Навигация
    case selectAndNavigate
    case navigateBack
    case navigateToRoot
    
    // Скролл колесиком
    case scrollUp
    case scrollDown
    
    // Загрузка данных
    case loadMediaLibrary
    case mediaLibraryLoaded
    case mediaLibraryError(String?)
    
    // Выбор элемента (без навигации)
    case selectItem(at: Int)
  }
  
  // MARK: - Dependencies
  
  @Dependency(\.menuService) var menuService
  
  // MARK: - Reducer
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .selectAndNavigate:
        guard let selected = state.selectedItem else {
          return .none
        }
        
        // Если у элемента есть дети - переходим к ним
        if selected.hasChildren {
          state.navigationPath.append(state.currentItem)
          state.currentItem = selected
          state.selectedIndex = 0
        } else {
          // Для треков и плейлистов - пока ничего не делаем
          // (будет обработано в PodFeature)
          print("Selected playable item: \(selected.title)")
        }
        return .none
        
      case .navigateBack:
        guard let previousItem = state.navigationPath.popLast() else {
          return .none
        }
        state.currentItem = previousItem
        state.selectedIndex = 0
        return .none
        
      case .navigateToRoot:
        guard let root = state.navigationPath.first else { return .none }
        state.currentItem = root
        state.navigationPath = []
        state.selectedIndex = 0
        return .none
        
      case .scrollUp:
        if state.selectedIndex > 0 {
          state.selectedIndex -= 1
        }
        return .none
        
      case .scrollDown:
        if state.selectedIndex < state.currentItems.count - 1 {
          state.selectedIndex += 1
        }
        return .none
        
      case .selectItem(let index):
        let safeIndex = max(0, min(index, state.currentItems.count - 1))
        state.selectedIndex = safeIndex
        return .none
        
      case .loadMediaLibrary:
        state.isLoading = true
        state.errorMessage = nil
        
        return .run { send in
          do {
            try await menuService.loadMediaLibrary()
            await send(.mediaLibraryLoaded)
          } catch {
            await send(.mediaLibraryError(error.localizedDescription))
          }
        }
        
      case .mediaLibraryLoaded:
        state.isLoading = false
        
        // Обновляем текущий элемент из сервиса
        if let updatedItem = menuService.item(withId: state.currentItem.id) {
          state.currentItem = updatedItem
        }
        return .none
        
      case .mediaLibraryError(let errorText):
        state.isLoading = false
        state.errorMessage = errorText
        return .none
      }
    }
  }
}
