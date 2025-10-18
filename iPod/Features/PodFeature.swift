import ComposableArchitecture
import Foundation
import MediaPlayer

@Reducer
struct PodFeature {

  
  // MARK: - State
  
  @ObservableState
  struct State: Equatable {
    var menu: MenuFeature.State = .init()
  }
  
  
  // MARK: - Action
  
  enum Action: Equatable {
    case menu(MenuFeature.Action)
    case buttonPressed(WheelButtonType)
    case scrolled(WheelScrollDirection)
  }

  
  // MARK: - Reducer
  
  var body: some ReducerOf<Self> {
    Scope(state: \.menu, action: \.menu) {
      MenuFeature()
    }

    Reduce { state, action in
      switch action {
      case .buttonPressed(let button):
        switch button {
        case .menu:
          return .send(.menu(.goBack))
        case .next:
          break
        case .previous:
          break
        case .play:
          break
        case .center:
          return .send(.menu(.enterSelectedItem))
        }
        return .none
        
      case .scrolled(let direction):
        return .send(.menu(.scroll(direction.toMenuDirection())))
        
      case .menu(_):
        return .none
      }
    }
  }
}

