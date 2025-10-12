import SwiftUI

struct ScrollWheelView: View {
  
  // MARK: - Parameters
  
  let diameter: CGFloat
  let onButtonPress: (WheelButtonType) -> Void
  let onScroll: (WheelScrollDirection) -> Void
  
  
  // MARK: - Private Parameters
  
  @State private var touchedButton: WheelButtonType? = nil
  @State private var isScrolling = false
  @State private var initialAngle: CGFloat = 0.0
  
  private var borderColor: Color {
    Color.gray.opacity(0.7)
  }
  
  
  // MARK: - Init
  
  init(
    diameter: CGFloat,
    onButtonPress: @escaping (WheelButtonType) -> Void,
    onScroll: @escaping (WheelScrollDirection) -> Void
  ) {
    self.diameter = diameter
    self.onButtonPress = onButtonPress
    self.onScroll = onScroll
  }
  
  
  // MARK: - Body
  
  var body: some View {
    ZStack {
      Image(.bevel)
        .resizable()
      wheelOverlay(diameter: diameter)
    }
    .frame(width: diameter, height: diameter)
  }
  
  
  // MARK: - Wheel Overlay
  
  private func wheelOverlay(diameter: CGFloat) -> some View {
    Group {
      let wheelDiameter = diameter * 0.81
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
          
          if let button = WheelButtonType(rawValue: index) {
            let size = button.getSize(for: diameter)
            
            Image(button.icon)
              .resizable()
              .frame(width: size.width, height: size.height)
              .rotationEffect(.degrees(Double(90 - (90 * index))))
              .padding(index % 2 == 0 ? 0 : 4)
              .frame(maxHeight: diameter, alignment: .bottom)
              .rotationEffect(.degrees(Double(index) * 90))
              .rotationEffect(.degrees(315))
          }
            
          Rectangle()
            .fill(borderColor)
            .frame(width: 1, height: (diameter - wheelDiameter) / 2)
            .frame(maxHeight: diameter, alignment: .bottom)
            .rotationEffect(.degrees(Double(index) * 90))
        }
        .rotationEffect(.degrees(-45))
        
        Circle()
          .strokeBorder(borderColor, lineWidth: 1)
          .frame(width: wheelDiameter, height: wheelDiameter)
        
        Circle()
          .strokeBorder(borderColor, lineWidth: 1)
          .frame(width: diameter, height: diameter)
        
        Group {
          Circle()
            .stroke(borderColor, lineWidth: 1)
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
      .shadow(radius: 1)
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
    let degrees = angle <= 0 ? angle + 360 : angle
    
    switch distance {
    case 0..<(centerDiameter / 2):
      handleButtonPress(.center)
      
    case (centerDiameter / 2)..<(wheelDiameter / 2):
      handleScroll(degrees: degrees)
      
    case (wheelDiameter / 2)..<(diameter / 2):
      if degrees < 45 || degrees > 315 {
        handleButtonPress(.next)
        
      } else if (45..<135).contains(degrees) {
        handleButtonPress(.play)
        
      } else if (135..<225).contains(degrees) {
        handleButtonPress(.previous)
        
      } else if (225..<315).contains(degrees) {
        handleButtonPress(.menu)
      }
      
    default: break
    }
  }
  
  private func handleButtonPress(_ button: WheelButtonType) {
    guard touchedButton == nil else { return }
    
    isScrolling = false
    touchedButton = button
    onButtonPress(button)
    Haptics.shared.play(.rigid)
  }
  
  private func handleScroll(degrees: CGFloat) {
    touchedButton = nil
    
    guard isScrolling else {
      isScrolling = true
      initialAngle = degrees
      return
    }
    
    var delta = degrees - initialAngle
    
    if initialAngle > 270.0 && initialAngle <= 360.0,
       degrees >= 0.0 && degrees < 90.0 {
      delta = 360.0 - initialAngle + degrees;
    }
    
    if initialAngle >= 0.0 && initialAngle < 90.0,
       degrees > 270.0 && degrees <= 360.0 {
      delta = -((360.0 - degrees) + initialAngle);
    }
    
    if abs(delta) > 18 {
      onScroll(delta > 0 ? .right : .left)
      Haptics.shared.play(.soft)
      initialAngle = degrees
    }
  }
}

struct ScrollWheelView_Previews: PreviewProvider {
  static var previews: some View {
    ScrollWheelView(diameter: 300) { button in
      print("Button Pressed: \(button)")
    } onScroll: { direction in
      print("Scrolled: \(direction)")
    }
    .padding(40)
  }
}
