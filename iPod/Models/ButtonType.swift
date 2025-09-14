import SwiftUI

enum ButtonType: Int {
  case next
  case play
  case previous
  case menu
  case center
  
  var icon: Image {
    switch self {
    case .play:
      Image(uiImage: .checkmark)
    case .menu:
      Image(uiImage: .actions)
    case .next:
      Image(uiImage: .add)
    case .previous:
      Image(uiImage: .remove)
    case .center:
      Image(uiImage: .strokedCheckmark)
    }
  }
}
