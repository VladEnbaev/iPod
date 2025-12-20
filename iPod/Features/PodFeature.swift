import ComposableArchitecture
import Foundation

// MARK: - Main App Feature

@Reducer
struct PodFeature {
  
  // MARK: - State
  
  @ObservableState
  struct State: Equatable {
    var menu: MenuFeature.State
    
    init() {
      let rootItem = MenuItem(
        title: "iPod",
        type: .folder,
        children: [
          MenuItem(title: "Loading...", type: .folder, children: [])
        ]
      )
      self.menu = MenuFeature.State(rootItem: rootItem)
    }
  }
  
  // MARK: - Action
  
  enum Action: Equatable {
    case menu(MenuFeature.Action)
    case wheelButtonPressed(WheelButtonType)
    case wheelScrolled(WheelScrollDirection)
    case initializeMenu
  }

  // MARK: - Dependencies
      
  @Dependency(\.menuService) var menuService
  
  // MARK: - Reducer
  
  var body: some ReducerOf<Self> {
    Scope(state: \.menu, action: \.menu) {
      MenuFeature()
    }
    
    Reduce { state, action in
      switch action {
      case .initializeMenu:
        // Инициализируем с реальным корневым элементом из сервиса
        let root = menuService.root()
        state.menu = MenuFeature.State(rootItem: root)
        
        // Начинаем загрузку медиатеки
        return .send(.menu(.loadMediaLibrary))
        
      case .wheelButtonPressed(let button):
        return handleWheelButton(button, state: &state)
        
      case .wheelScrolled(let direction):
        return handleWheelScroll(direction, state: &state)
        
      case .menu:
        return .none
      }
    }
  }
  
  // MARK: - Private Helpers
  
  private func handleWheelButton(_ button: WheelButtonType, state: inout State) -> Effect<Action> {
    switch button {
    case .menu:
      return .send(.menu(.navigateBack))
      
    case .center:
      return .send(.menu(.selectAndNavigate))
      
    case .play:
      // Для теста: если выбрали трек - выводим в консоль
      if let selected = state.menu.selectedItem,
         selected.type == .track {
        print("Would play: \(selected.title)")
      }
      return .none
      
    case .next, .previous:
      // Пока не используется
      return .none
    }
  }
  
  private func handleWheelScroll(_ direction: WheelScrollDirection, state: inout State) -> Effect<Action> {
    switch direction {
    case .left:
      return .send(.menu(.scrollUp))
    case .right:
      return .send(.menu(.scrollDown))
    }
  }
}
