import SwiftUI
import ComposableArchitecture

// MARK: - DisplayView

struct DisplayView: View {
  
  // MARK: - Properties
  
  let store: StoreOf<PodFeature>
  @Environment(\.scenePhase) private var scenePhase
  
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
      displayContent
      .background(Color.Pod.displayWhite)
      .clipShape(.rect(cornerRadius: cornerRadius))
      .overlay {
        displayBorder
      }
      .onChange(of: store.menuTree.rootItem().id) { rootID in
        menuNavigationPath[0] = rootID
      }
    }
    .onChange(of: scenePhase) { newPhase in
      guard newPhase == .active else { return }
      openNowPlayingIfNeeded()
    }
  }
}

// MARK: - Methods

private extension DisplayView {
  var displayContent: some View {
    VStack(spacing: .zero) {
      headerView
        .offset(y: 2)
        .zIndex(1)
      
      MenuView(
        store: store,
        navigationPath: $menuNavigationPath
      )
      .zIndex(0)
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .padding(6)
  }

  var headerView: some View {
    DisplayHeaderView(
      title: title(for: menuNavigationPath.last ?? UUID()),
      status: store.player.isPlaying ? .playing : .paused
    )
  }

  var displayBorder: some View {
    let shadowRadius: CGFloat = 2

    return RoundedRectangle(cornerRadius: cornerRadius)
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

  func openNowPlayingIfNeeded() {
    guard store.player.isPlaying else { return }
    guard store.player.currentTrack != nil else { return }
    guard let currentScreenID = menuNavigationPath.last else { return }

    if currentScreenID == PodFeature.nowPlayingMenuID {
      return
    }

    if store.menuTree.item(withId: currentScreenID)?.isPlayable == true {
      return
    }

    menuNavigationPath.removeAll { $0 == PodFeature.nowPlayingMenuID }
    menuNavigationPath.append(PodFeature.nowPlayingMenuID)
  }
}


#Preview {
  DisplayView(store: .init(initialState: PodFeature.State()) {
    PodFeature()
  })
  .frame(width: 300)
}
