import SwiftUI

struct ClickWheelView: View {
  
  
  // MARK: - Subtypes
  
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
  
  enum ScrollDirection {
    case left, right
  }
  
  
  // MARK: - Subtypes
  
  let diameter: CGFloat
  let onButtonPress: ((ButtonType) -> Void)?
  let onScroll: ((ScrollDirection) -> Void)?
  
  
  // MARK: - Private Parameters
  
  @State private var touchedButton: ButtonType? = nil
  @State private var isScrolling = false
  @State private var initialAngle: CGFloat = 0.0
  
  private var centerDiameter: CGFloat {
    diameter * 67/284
  }
  private var wheelDiameter: CGFloat {
    diameter * 200/284
  }
  private var buttonDiameter: CGFloat {
    diameter * 255/284
  }
  
  private var borderGradient: AngularGradient {
    AngularGradient(
      gradient: Gradient(colors: [
        Color.gray.opacity(0.7), // Сверху непрозрачная
        Color.gray.opacity(0.2), // Снизу прозрачная
        Color.gray.opacity(0.7)  // Снова сверху непрозрачная
      ]),
      center: .center,
      startAngle: .degrees(0), // Начало градиента сверху
      endAngle: .degrees(360) // Полный круг
    )
  }
  
  
  // MARK: - Init
  
  init(
    diameter: CGFloat = 300.0,
    onButtonPress: ((ButtonType) -> Void)? = nil,
    onScroll: ((ScrollDirection) -> Void)? = nil
  ) {
    self.diameter = diameter
    self.onButtonPress = onButtonPress
    self.onScroll = onScroll
  }
  
  
  // MARK: - Body
  
  var body: some View {
    Image(.bevel)
      .resizable()
      .overlay {
        wheelOverlay
          .padding()
      }
      .frame(width: diameter, height: diameter)
  }
  
  
  // MARK: - Wheel Overlay
  
  private var wheelOverlay: some View {
    ZStack(alignment: .center) {
      ForEach(0..<4) { index in
        Group {
          Circle()
            .trim(from: CGFloat(index) * 0.25, to: CGFloat(index + 1) * 0.25)
            .stroke(lineWidth: (buttonDiameter - wheelDiameter) / 2)
            .fill(touchedButton?.rawValue == index ? .black.opacity(0.1) : .clear)
            .frame(
              width: (buttonDiameter + wheelDiameter) / 2,
              height: (buttonDiameter + wheelDiameter) / 2
            )
            .rotationEffect(.degrees(Double(index) * 360))
          
          Rectangle()
            .fill(borderGradient)
            .frame(width: 1.5, height: (buttonDiameter - wheelDiameter) / 2)
            .frame(maxHeight: buttonDiameter, alignment: .bottom)
            .rotationEffect(.degrees(Double(index) * 90))
          
          Rectangle()
            .fill(borderGradient)
            .frame(width: 1.5, height: (buttonDiameter - wheelDiameter) / 2)
            .rotationEffect(.degrees(0))
            .frame(maxHeight: buttonDiameter, alignment: .top)
            .rotationEffect(.degrees(Double(index + 1) * 90))
        }
      }
      .rotationEffect(.degrees(-45))
      
      Circle()
        .strokeBorder(borderGradient, lineWidth: 1.5)
        .frame(width: wheelDiameter, height: wheelDiameter)
      
      Circle()
        .strokeBorder(borderGradient, lineWidth: 1.5)
        .frame(width: buttonDiameter, height: buttonDiameter)
      
      
      Group {
        Circle()
          .stroke(borderGradient, lineWidth: 1.5)
        Circle()
          .fill(touchedButton == .center ? Color.black.opacity(0.1) : Color.clear)
      }
      .frame(width: centerDiameter, height: centerDiameter)
      .onTapGesture {
        touchedButton = .center
        onButtonPress?(.center)
      }
    }
    .contentShape(.circle)
    .gesture(DragGesture(minimumDistance: 0)
      .onChanged { value in
        handleTouch(location: value.location)
      }
      .onEnded { _ in
        isScrolling = false
        touchedButton = nil
      }
    )
    .onChange(of: touchedButton) { newValue in
      print("Touch: \(touchedButton?.rawValue)")
    }
  }

}


// MARK: - Private Methods

extension ClickWheelView {
  
  private func handleTouch(location: CGPoint) {
    let center = CGPoint(x: diameter / 2, y: diameter / 2)
    let deltaX = location.x - center.x
    let deltaY = location.y - center.y
    let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
    let angle = atan2(deltaY, deltaX) * 180 / .pi
    let normalizedAngle = angle < 0 ? angle + 360 : angle
    
    switch distance {
    case 0..<(centerDiameter / 2):
      touchedButton = .center
      onButtonPress?(.center)
      
    case (centerDiameter / 2)..<(wheelDiameter / 2):
      if !isScrolling {
        initialAngle = normalizedAngle
        isScrolling = true
      } else {
        let delta = normalizedAngle - initialAngle
        if abs(delta) > 18 {
          onScroll?(delta > 0 ? .right : .left)
          initialAngle = normalizedAngle
        }
      }
      
    case (wheelDiameter / 2)..<(diameter / 2):
//      print(normalizedAngle)
      if normalizedAngle < 45 || normalizedAngle > 315 {
        touchedButton = .next
        
      } else if (45..<135).contains(normalizedAngle) {
        touchedButton = .play
        
      } else if (135..<225).contains(normalizedAngle) {
        touchedButton = .previous
        
      } else if (225..<315).contains(normalizedAngle) {
        touchedButton = .menu
      }
      
    default: break
    }
  }
}

struct ScrollWheelView_Previews: PreviewProvider {
  static var previews: some View {
    ClickWheelView(diameter: 350) { button in
      print("Button Pressed: \(button)")
    } onScroll: { direction in
      print("Scrolled: \(direction)")
    }
  }
}
