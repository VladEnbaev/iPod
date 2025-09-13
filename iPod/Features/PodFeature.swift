import ComposableArchitecture
import Foundation


@Reducer
struct PodFeature {
  @ObservableState
  struct State: Equatable {
    var selectedMenu: Menu = .main
    
    enum Menu: Equatable {
      case main
      case music
      case settings
      // и т.д.
    }
  }
  
  enum Action: Equatable {
    case buttonPressed(ClickWheelView.ButtonType)
    case scrolled(ClickWheelView.ScrollDirection)
    // Добавьте другие действия по необходимости
  }
  
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .buttonPressed(let button):
      // Обработка нажатий кнопок
      switch button {
      case .menu:
        state.selectedMenu = .main
      case .next:
        // логика перехода к следующему элементу
        break
      case .previous:
        // логика перехода к предыдущему элементу
        break
      case .play:
        // логика play/pause
        break
      case .center:
        // логика выбора
        break
      }
      return .none
    case .scrolled(let direction):
      // Обработка скролла
      switch direction {
      case .left:
        // логика скролла влево
        break
      case .right:
        // логика скролла вправо
        break
      }
      return .none
    }
  }
}
