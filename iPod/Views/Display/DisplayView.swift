import SwiftUI
import ComposableArchitecture

struct DisplayView: View {
  
  let store: StoreOf<PodFeature>
  
  let cornerRadius: CGFloat = 8
  
  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 2) {
        DisplayHeaderView(
          title: store.currentTrack.title,
          status: .playing
        )
        VStack(spacing: .zero) {
          ForEach(0..<store.currentItems.count, id: \.self) { index in
            WithPerceptionTracking {
              MenuItemView(
                text: store.currentItems[index].title,
                isSelected: store.selectedIndex == index
              )
            }
          }
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
    }
  }
}

#Preview {
  DisplayView(store: .init(initialState: PodFeature.State()) {
    PodFeature()
  })
  .frame(width: 300)
}
