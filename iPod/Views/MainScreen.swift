import SwiftUI
import ComposableArchitecture

struct MainScreen: View {
  
  let store: StoreOf<PodFeature>
  
  var body: some View {
    VStack(alignment: .center) {
      Spacer()
      
      WithPerceptionTracking {
        DisplayView(store: store)
          .frame(height: 220)
          .padding(.horizontal, 50)
          .padding(.bottom, 40)
      }
      
      GeometryReader { proxy in
        let diameter = min(proxy.size.width, proxy.size.height)
        
        ScrollWheelView(
          diameter: diameter,
          onButtonPress: { ScrollWheelEventsPublisher.shared.send(.buttonPressed($0)) },
          onScroll: { ScrollWheelEventsPublisher.shared.send(.scrolled($0)) }
        )
      }
      .padding(.horizontal, 30)
    }
    .padding(.vertical, 50)
    .background(Color.Pod.caseColor, ignoresSafeAreaEdges: [])
    .overlay {
      RoundedRectangle(cornerRadius: 35)
        .stroke(
          LinearGradient(
            stops: [
              .init(color: Color(hex: "D9DADD"), location: 0),
              .init(color: Color(hex: "737475"), location: 0.5),
              .init(color: Color(hex: "AAAFB5"), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
          ),
          lineWidth: 10
        )
    }
    .cornerRadius(35)
    .padding(.vertical, 30)
    .background(.black)
    .onAppear {
      store.send(.initializeMenu)
    }
  }
}

#Preview {
  MainScreen(store: .init(initialState: PodFeature.State()) {
    PodFeature()
  })
}
