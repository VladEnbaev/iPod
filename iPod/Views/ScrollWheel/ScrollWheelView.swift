import SwiftUI

struct ScrollWheelView: View {
  
  // MARK: - Parameters
  
  let onButtonPress: (ButtonType) -> Void
  let onScroll: (ScrollDirection) -> Void
  
  
  // MARK: - Private Parameters
  
  @State private var touchedButton: ButtonType? = nil
  @State private var isScrolling = false
  @State private var initialAngle: CGFloat = 0.0
  
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
    onButtonPress: @escaping (ButtonType) -> Void,
    onScroll: @escaping (ScrollDirection) -> Void
  ) {
    self.onButtonPress = onButtonPress
    self.onScroll = onScroll
  }
  
  
  // MARK: - Body
  
  var body: some View {
    GeometryReader { proxy in
      let diameter = min(proxy.size.width, proxy.size.height)
      
      ZStack {
        Image(.bevel)
          .resizable()
        wheelOverlay(diameter: diameter)
      }
      .frame(width: diameter, height: diameter)
    }
  }
  
  
  // MARK: - Wheel Overlay
  
  private func wheelOverlay(diameter: CGFloat) -> some View {
    Group {
      let wheelDiameter = diameter * 0.8
      let centerDiameter = diameter * 0.25
      
      ZStack(alignment: .center) {
        ForEach(0..<4) { index in
          Circle()
            .trim(from: CGFloat(index) * 0.25, to: CGFloat(index + 1) * 0.25)
            .stroke(lineWidth: (diameter - wheelDiameter) / 2)
            .fill(touchedButton?.rawValue == index ? .black.opacity(0.1) : .clear)
            .frame(
              width: (diameter + wheelDiameter) / 2,
              height: (diameter + wheelDiameter) / 2
            )
            .rotationEffect(.degrees(Double(index) * 360))
          
          Rectangle()
            .fill(borderGradient)
            .frame(width: 1.5, height: (diameter - wheelDiameter) / 2)
            .frame(maxHeight: diameter, alignment: .bottom)
            .rotationEffect(.degrees(Double(index) * 90))
        }
        .rotationEffect(.degrees(-45))
        
        Circle()
          .strokeBorder(borderGradient, lineWidth: 1.5)
          .frame(width: wheelDiameter, height: wheelDiameter)
        
        Circle()
          .strokeBorder(borderGradient, lineWidth: 1.5)
          .frame(width: diameter, height: diameter)
        
        
        Group {
          Circle()
            .stroke(borderGradient, lineWidth: 1.5)
          Circle()
            .fill(touchedButton == .center ? Color.black.opacity(0.1) : Color.clear)
        }
        .frame(width: centerDiameter, height: centerDiameter)
      }
      .contentShape(.circle)
      .gesture(DragGesture(minimumDistance: 0)
        .onChanged { value in
          handleTouch(
            location: value.location,
            diameter: diameter,
            wheelDiameter: wheelDiameter,
            centerDiameter: centerDiameter
          )
        }
        .onEnded { _ in
          isScrolling = false
          touchedButton = nil
        }
      )
    }
  }
}


// MARK: - Private Methods

extension ScrollWheelView {
  
  private func handleTouch(
    location: CGPoint,
    diameter: CGFloat,
    wheelDiameter: CGFloat,
    centerDiameter: CGFloat
  ) {
    let center = CGPoint(x: diameter / 2, y: diameter / 2)
    let deltaX = location.x - center.x
    let deltaY = location.y - center.y
    let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
    let angle = atan2(deltaY, deltaX) * 180 / .pi
    let normalizedAngle = angle < 0 ? angle + 360 : angle
    
    switch distance {
    case 0..<(centerDiameter / 2):
      touchedButton = .center
      onButtonPress(.center)
      
    case (centerDiameter / 2)..<(wheelDiameter / 2):
      if !isScrolling {
        initialAngle = normalizedAngle
        isScrolling = true
      } else {
        let delta = normalizedAngle - initialAngle
        if abs(delta) > 18 {
          onScroll(delta > 0 ? .right : .left)
          initialAngle = normalizedAngle
        }
      }
      
    case (wheelDiameter / 2)..<(diameter / 2):
      if normalizedAngle < 45 || normalizedAngle > 315 {
        touchedButton = .next
        onButtonPress(.next)
        
      } else if (45..<135).contains(normalizedAngle) {
        touchedButton = .play
        onButtonPress(.play)
        
      } else if (135..<225).contains(normalizedAngle) {
        touchedButton = .previous
        onButtonPress(.previous)
        
      } else if (225..<315).contains(normalizedAngle) {
        touchedButton = .menu
        onButtonPress(.menu)
      }
      
    default: break
    }
  }
}

struct ScrollWheelView_Previews: PreviewProvider {
  static var previews: some View {
    ScrollWheelView() { button in
      print("Button Pressed: \(button)")
    } onScroll: { direction in
      print("Scrolled: \(direction)")
    }
    .padding(40)
  }
}
