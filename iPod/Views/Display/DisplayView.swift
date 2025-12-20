import SwiftUI
import ComposableArchitecture

// MARK: - DisplayView

struct DisplayView: View {
  
  let store: StoreOf<PodFeature>
  let cornerRadius: CGFloat = 8
  
  var body: some View {
    VStack(spacing: 2) {
      WithPerceptionTracking {
        DisplayHeaderView(
          title: store.menu.title,
          status: .playing
        )
      }
      
      ZStack {
        WithPerceptionTracking {
          MenuView(
            store: store.scope(
              state: \.menu,
              action: \.menu
            )
          )
        }
      }
      .frame(maxHeight: .infinity)
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
  }
}


#Preview {
  DisplayView(store: .init(initialState: PodFeature.State()) {
    PodFeature()
  })
  .frame(width: 300)
}
