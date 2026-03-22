import SwiftUI

// MARK: - PlayerProgressView

struct PlayerProgressView: View {

  // MARK: - Properties

  let progress: Double
  let timeElapsed: String
  let timeRemaining: String

  private let barHeight: CGFloat = 14
  private let barLineWidth: CGFloat = 1.8

  private var clampedProgress: CGFloat {
    CGFloat(min(1, max(0, progress)))
  }
  
  private var cornerRadius: CGFloat {
    barHeight / 2.5
  }

  // MARK: - Body

  var body: some View {
    HStack(spacing: 12) {
      Text(timeRemaining)
        .font(.chicagoRegular(size: 24))
        .foregroundStyle(Color.Pod.displayBlack)
      
      GeometryReader { geo in
        let innerHeight = max(0, barHeight)
        let innerWidth = max(0, geo.size.width - barLineWidth * 2)
        let fillWidth = innerWidth * clampedProgress
        
        if innerHeight > 0 && fillWidth > 0 {
          Rectangle()
            .fill(Color.Pod.displayBlack)
            .frame(width: fillWidth, height: innerHeight)
            .offset(x: barLineWidth / 2)
        }
      }
      .frame(height: barHeight)
      .cornerRadius(cornerRadius)
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(Color.Pod.displayBlack, lineWidth: barLineWidth)
      )
    }
  }
}

#Preview {
  PlayerProgressView(progress: 0.5, timeElapsed: "2:24", timeRemaining: "-2:21")
    .padding(30)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
}
