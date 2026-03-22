import SwiftUI

// MARK: - PlayerVolumeView

struct PlayerVolumeView: View {

  // MARK: - Properties

  let volume: Double

  private let barHeight: CGFloat = 14
  private let barLineWidth: CGFloat = 1.8

  private var clampedVolume: CGFloat {
    CGFloat(min(1, max(0, volume)))
  }

  // MARK: - Body

  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      Image(.speakerOff)
        .resizable()
        .renderingMode(.template)
        .frame(width: 20, height: 20)
        .foregroundStyle(Color.Pod.displayBlack)

      GeometryReader { geo in
        let innerHeight = max(0, barHeight)
        let innerWidth = max(0, geo.size.width - barLineWidth * 2)
        let fillWidth = innerWidth * clampedVolume

        ZStack(alignment: .leading) {
          if innerHeight > 0 && fillWidth > 0 {
            Rectangle()
              .fill(Color.Pod.displayBlack)
              .frame(width: fillWidth, height: innerHeight)
              .offset(x: barLineWidth / 2)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      }
      .frame(height: barHeight)
      .background(Color.Pod.displayWhite)
      .overlay(
        Rectangle()
          .stroke(Color.Pod.displayBlack, lineWidth: barLineWidth)
      )

      Image(.speakerOn)
        .resizable()
        .renderingMode(.template)
        .frame(width: 30, height: 30)
        .foregroundStyle(Color.Pod.displayBlack)
    }
    .padding(.horizontal, 6)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  }
}

#Preview {
  PlayerVolumeView(volume: 0.7)
    .frame(width: 260, height: 80)
    .padding()
    .background(Color.Pod.displayWhite)
}
