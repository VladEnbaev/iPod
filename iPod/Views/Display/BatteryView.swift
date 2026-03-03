import SwiftUI
import UIKit

struct BatteryView: View {
  
  // MARK: - Private Properties

  @State private var batteryState: UIDevice.BatteryState = .unknown
  @State private var batteryLevel: Float = 0
  
  @State private var chargingTimerStep: Int = 0
  @State private var chargingTimer = Timer.publish(every: 0.5, on: .main, in: .common)
    .autoconnect()
  
  private let batteryStateDidChange = NotificationCenter.default.publisher(
    for: UIDevice.batteryStateDidChangeNotification
  )
  private let batteryLevelDidChange = NotificationCenter.default.publisher(
    for: UIDevice.batteryLevelDidChangeNotification
  )
  
  // MARK: - Body

  var body: some View {
    batteryShape
      .onAppear {
        UIDevice.current.isBatteryMonitoringEnabled = true
        refreshBatteryStatus()
      }
      .onDisappear {
        UIDevice.current.isBatteryMonitoringEnabled = false
      }
      .onReceive(batteryStateDidChange) { _ in
        refreshBatteryStatus()
      }
      .onReceive(batteryLevelDidChange) { _ in
        refreshBatteryStatus()
      }
      .onReceive(chargingTimer) { _ in
        guard batteryState == .charging else {
          chargingTimerStep = 0
          return
        }

        chargingTimerStep = chargingTimerStep == 4 ? 0 : chargingTimerStep + 1
      }
  }
  
  // MARK: - Subviews

  private var batteryShape: some View {
    ZStack(alignment: .leading) {
      Path { path in
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 30, y: 0))
        path.addLine(to: CGPoint(x: 30, y: 5))
        path.addLine(to: CGPoint(x: 32, y: 5))
        path.addLine(to: CGPoint(x: 32, y: 11))
        path.addLine(to: CGPoint(x: 30, y: 11))
        path.addLine(to: CGPoint(x: 30, y: 16))
        path.addLine(to: CGPoint(x: 0, y: 16))
        path.closeSubpath()
      }
      .stroke(Color.Pod.displayBlack, lineWidth: 2)
      .frame(width: 32, height: 16)

      if batteryState != .unknown {
        HStack(spacing: 1) {
          ForEach(0..<4, id: \.self) { index in
            Rectangle()
              .fill(index < numberOfBars ? Color.Pod.displayBlack : Color.Pod.displayBlack.opacity(0.2))
          }
        }
        .padding(2)
        .frame(width: 30, height: 16)
      }
    }
  }

  private var numberOfBars: Int {
    if batteryState == .charging {
      return chargingTimerStep
    }

    if batteryLevel >= 0.80 {
      return 4
    }
    if batteryLevel >= 0.60 {
      return 3
    }
    if batteryLevel >= 0.40 {
      return 2
    }
    if batteryLevel >= 0.20 {
      return 1
    }

    return 0
  }
}

// MARK: - Methods

private extension BatteryView {
  private func refreshBatteryStatus() {
    batteryState = UIDevice.current.batteryState
    batteryLevel = max(UIDevice.current.batteryLevel, 0)
  }
}

#Preview {
  BatteryView()
    .frame(width: 50, height: 50)
    .background(Color.Pod.displayWhite)
}
