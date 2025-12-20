import SwiftUI
import ComposableArchitecture

// MARK: - MenuView

struct MenuView: View {
  
  // MARK: - Properties
  
  let store: StoreOf<PodFeature>
  @Binding var navigationPath: [UUID]
  
  // MARK: - Init
  
  init(store: StoreOf<PodFeature>, navigationPath: Binding<[UUID]>) {
    self.store = store
    self._navigationPath = navigationPath
  }
  
  // MARK: - Body
  
  var body: some View {
    ZStack {
      ForEach(navigationPath.indices, id: \.self) { index in
        let itemId = navigationPath[index]
        let isActive = index == navigationPath.count - 1
        
        WithPerceptionTracking {
          // Основной контент меню
          if let children = store.menuTree.item(withId: itemId)?.children {
            MenuPageView(
              items: children,
              isActive: isActive,
              onSelect: { selectAndNavigate($0) }
            )
            .offset(x: isActive ? 0 : (index < navigationPath.count - 1 ? -300 : 300))
            .opacity(isActive ? 1 : 0)
            .transition(
              .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .slide
              )
            )
          }
        }
      }
    }
    .animation(.smooth(duration: 0.2), value: navigationPath.count)
    .onReceive(ScrollWheelEventsPublisher.shared.events) { event in
      // Отправляем действие в store
      switch event {
      case let .buttonPressed(button):
        guard button == .menu else { return }
        navigateBack()
      default: break
      }
    }
  }
  
  private func selectAndNavigate(_ selectedId: UUID) {
    guard let selected = store.menuTree.item(withId: selectedId) else { return }
    
    if selected.hasChildren {
      // Сохраняем текущий ID в историю
      navigationPath.append(selected.id)
      
    } else if selected.isPlayable {
      // Для треков и плейлистов - можно воспроизвести
      print("Selected playable item: \(selected.title)")
      // Здесь будет логика плеера
    }
  }
  
  private func navigateBack() {
    guard navigationPath.count > 1 else { return }
    
    navigationPath.removeLast()
  }
}

#Preview {
  MainScreen(store: .init(initialState: PodFeature.State()) {
    PodFeature()
  })
}
