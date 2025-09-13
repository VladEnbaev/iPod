import SwiftUI

@main
struct PodApp: App {
  var body: some Scene {
    WindowGroup {
      MainScreen()
        .onAppear {
          for family in UIFont.familyNames.sorted() {
              let names = UIFont.fontNames(forFamilyName: family)
              print("Family: \(family) Font names: \(names)")
          }
        }
    }
  }
}
