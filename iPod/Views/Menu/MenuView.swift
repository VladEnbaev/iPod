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
        page(for: index)
      }
    }
    .animation(.smooth(duration: 0.2), value: navigationPath.count)
    .onReceive(ScrollWheelEventsPublisher.shared.events) { event in
      switch event {
      case let .buttonPressed(button):
        guard button == .menu else { return }
        navigateBack()
      default: break
      }
    }
  }
  
  // MARK: - Page
  
  @ViewBuilder
  func page(for index: Int) -> some View {
    WithPerceptionTracking {
      
      let itemId = navigationPath[index]
      let isActive = index == navigationPath.count - 1
      
      Group {
        if itemId == PodFeature.nowPlayingMenuID {
          PlayerView(
            store: store.scope(state: \.player, action: \.player)
          )
        } else if let item = store.menuTree.item(withId: itemId), item.isPlayable {
          PlayerView(
            store: store.scope(state: \.player, action: \.player)
          )
          
        } else if let children = items(for: itemId) {
          MenuPageView(
            items: children,
            isActive: isActive,
            onSelect: { selectAndNavigate($0) }
          )
        }
      }
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
  
// MARK: - Private Methods

private extension MenuView {
  private func items(for itemId: UUID) -> [MenuItem]? {
    guard let item = store.menuTree.item(withId: itemId) else { return nil }

    var items = item.children

    if item.id == store.menuTree.rootItem().id, store.player.currentTrack != nil {
      items.append(
        MenuItem(
          id: PodFeature.nowPlayingMenuID,
          title: "Now Playing",
          type: .folder,
          children: []
        )
      )
    }

    return items
  }
  
  private func selectAndNavigate(_ selectedId: UUID) {
    if selectedId == PodFeature.nowPlayingMenuID {
      navigationPath.append(selectedId)
      return
    }

    guard let selected = store.menuTree.item(withId: selectedId) else { return }
    navigationPath.append(selectedId)
    
    if selected.isPlayable {
      store.send(.menuItemSelected(selectedId))
    }
  }
  
  private func navigateBack() {
    guard navigationPath.count > 1 else { return }
    
    navigationPath.removeLast()
  }
}
