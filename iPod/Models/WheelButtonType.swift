import SwiftUI

enum WheelButtonType: Int {
  case next
  case play
  case previous
  case menu
  case center
  
  var icon: ImageResource {
    switch self {
    case .play: .playPause
    case .menu: .menu
    case .next: .next
    case .previous: .previous
    case .center: .playPause
    }
  }
  
  func getSize(for diameter: CGFloat) -> CGSize {
    switch self {
    case .menu:
      CGSize(width: diameter * 0.25, height: diameter * 0.07)
    case .next, .previous:
      CGSize(width: diameter * 0.098, height: diameter * 0.098)
    case .play:
      CGSize(width: diameter * 0.17, height: diameter * 0.088)
    case .center:
      CGSize(width: 0, height: 0)
    }
  }
}
