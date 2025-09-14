import SwiftUI
import ComposableArchitecture

struct MainScreen: View {
  
  let store: StoreOf<PodFeature>
  
  var body: some View {
    VStack(spacing: 40) {
      Spacer()
      
      DisplayView(store: store)
        .frame(height: 220)
        .padding(.horizontal, 50)
      
      ScrollWheelView(
        onButtonPress: { store.send(.buttonPressed($0)) },
        onScroll: { store.send(.scrolled($0)) }
      )
      .padding(.horizontal, 30)
      
      Spacer()
    }
    .frame(maxHeight: .infinity, alignment: .center)
    .background(.white)
  }
}

#Preview {
  MainScreen(store: .init(initialState: PodFeature.State()) {
    PodFeature()
  })
}
