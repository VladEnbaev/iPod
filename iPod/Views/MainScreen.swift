import SwiftUI
import ComposableArchitecture

struct MainScreen: View {
  
  let store: StoreOf<PodFeature>
  
  var body: some View {
    VStack(alignment: .center, spacing: .zero) {
      WithPerceptionTracking {
        DisplayView(store: store)
          .frame(width: 300, height: 230)
          .padding(.bottom, 30)
          .padding(.top, 30)
      }
      
      ScrollWheelView(
        diameter: 320,
        onButtonPress: { ScrollWheelEventsPublisher.shared.send(.buttonPressed($0)) },
        onScroll: { ScrollWheelEventsPublisher.shared.send(.scrolled($0)) }
      )
      .padding(.bottom, 30)
    }
    .frame(maxWidth: .infinity)
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
    .onReceive(ScrollWheelEventsPublisher.shared.events) { event in
      // iPod-like behavior: MENU closes the player screen.
      switch event {
      case let .buttonPressed(button):
        switch button {
        case .next:
          store.send(.player(.nextTrack))
        case .previous:
          store.send(.player(.previousTrack))
        case .play:
          store.send(.player(.togglePlayPause))
        default: break
        }
      default:
        break
      }
    }
  }
}

#Preview {
  MainScreen(store: .init(initialState: PodFeature.State()) {
    PodFeature()
  })
}
