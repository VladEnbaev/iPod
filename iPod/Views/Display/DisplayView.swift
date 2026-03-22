import SwiftUI
import ComposableArchitecture

// MARK: - DisplayView

struct DisplayView: View {
  
  // MARK: - Properties
  
  let store: StoreOf<PodFeature>
  
  // MARK: - Private Properties
  
  private let cornerRadius: CGFloat = 8
  @State private var menuNavigationPath: [UUID]
  
  // MARK: - Init
  
  init(store: StoreOf<PodFeature>) {
    self.store = store
    menuNavigationPath = [store.menuTree.rootItem().id]
  }
  
  // MARK: - Body
  
  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: .zero) {
        WithPerceptionTracking {
          DisplayHeaderView(
            title: title(for: menuNavigationPath.last ?? UUID()),
            status: store.player.isPlaying ? .playing : .paused
          )
        }
        .offset(y: 2)
        .zIndex(1)
        
        WithPerceptionTracking {
          MenuView(
            store: store,
            navigationPath: $menuNavigationPath
          )
        }
        .zIndex(0)
      }
      .frame(maxHeight: .infinity, alignment: .top)
      .padding(6)
      .overlay {
        let shadowRadius: CGFloat = 2
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(Color.black.opacity(0.2), lineWidth: 4)
          .shadow(
            color: Color.black, radius: shadowRadius, x: shadowRadius, y: shadowRadius
          )
          .clipShape(
            RoundedRectangle(cornerRadius: cornerRadius)
          )
          .shadow(
            color: Color.black, radius: shadowRadius, x: -shadowRadius, y: -shadowRadius
          )
          .clipShape(
            RoundedRectangle(cornerRadius: cornerRadius)
          )
      }
      .background(Color.Pod.displayWhite)
      .clipShape(.rect(cornerRadius: cornerRadius))
      .onChange(of: store.menuTree.rootItem()) { item in
        menuNavigationPath[0] = item.id
      }
    }
  }
}

// MARK: - Methods

private extension DisplayView {
  
  func title(for id: UUID) -> String {
    if id == PodFeature.nowPlayingMenuID {
      return "Now Playing"
    }

    let item = store.menuTree.item(withId: id)
    
    if item?.isPlayable == true {
      return "Now Playing"
    }
    
    return item?.title ?? store.menuTree.rootItem().title
  }
}


#Preview {
  DisplayView(store: .init(initialState: PodFeature.State()) {
    PodFeature()
  })
  .frame(width: 300)
}
