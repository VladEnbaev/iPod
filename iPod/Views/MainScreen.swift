import SwiftUI
import ComposableArchitecture

struct MainScreen: View {
  
  let store: StoreOf<PodFeature>
  
  var body: some View {
    VStack(alignment: .center) {
      Spacer()
      
      DisplayView(store: store)
        .frame(height: 220)
        .padding(.horizontal, 50)
        .padding(.bottom, 40)
      
      GeometryReader { proxy in
        let diameter = min(proxy.size.width, proxy.size.height)
        
        ScrollWheelView(
          diameter: diameter,
          onButtonPress: { store.send(.buttonPressed($0)) },
          onScroll: { store.send(.scrolled($0)) }
        )
      }
      .padding(.horizontal, 30)
    }
    .padding(.vertical, 50)
    .background(Color.Pod.caseColor)
  }
}

#Preview {
  MainScreen(store: .init(initialState: PodFeature.State()) {
    PodFeature()
  })
}
