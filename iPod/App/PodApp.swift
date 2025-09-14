import SwiftUI

@main
struct PodApp: App {
  var body: some Scene {
    WindowGroup {
      MainScreen(store: .init(initialState: PodFeature.State()) {
        PodFeature()
      })
    }
  }
}
