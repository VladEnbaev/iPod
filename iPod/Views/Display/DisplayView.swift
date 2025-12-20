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
      VStack(spacing: 2) {
        WithPerceptionTracking {
          DisplayHeaderView(
            title: store.menuTree.item(
              withId: menuNavigationPath.last ?? UUID()
            )?.title ?? store.menuTree.rootItem().title,
            status: .playing
          )
        }
        
        WithPerceptionTracking {
          MenuView(
            store: store,
            navigationPath: $menuNavigationPath
          )
        }
      }
      .frame(maxHeight: .infinity, alignment: .top)
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


#Preview {
  DisplayView(store: .init(initialState: PodFeature.State()) {
    PodFeature()
  })
  .frame(width: 300)
}
