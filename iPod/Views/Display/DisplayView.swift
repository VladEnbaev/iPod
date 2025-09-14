import SwiftUI
import ComposableArchitecture

struct DisplayView: View {
  
  let store: StoreOf<PodFeature>
  
  let cornerRadius: CGFloat = 8
  
  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: .zero) {
        ForEach(0..<store.currentItems.count, id: \.self) { index in
          MenuItemView(
            text: store.currentItems[index].title,
            isSelected: store.selectedIndex == index
          )
        }
      }
      .frame(maxHeight: .infinity, alignment: .top)
      .background(Color.Pod.displayWhite)
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(Color.black.opacity(0.2), lineWidth: 3)
          .shadow(radius: 3, x: 5, y: 5)
          .clipShape(
            RoundedRectangle(cornerRadius: cornerRadius)
          )
          .shadow(radius: 2, x: -2, y: -2)
          .clipShape(
            RoundedRectangle(cornerRadius: cornerRadius)
          )
      )
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
