enum WheelScrollDirection {
  case left, right
  
  func toMenuDirection() -> MenuScrollDirection {
    switch self {
    case .left: return .top
    case .right: return .bottom
    }
  }
}
