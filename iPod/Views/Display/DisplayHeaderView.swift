import SwiftUI

struct DisplayHeaderView: View {
  
  enum Status {
    case playing
    case paused
  }
  
  let title: String
  let status: Status?
  
  init(title: String, status: Status? = nil) {
    self.title = title
    self.status = status
  }
  
  var body: some View {
    VStack(spacing: .zero) {
      HStack(spacing: .zero) {
        trackStatusView
        Spacer()
      }
      .padding(.horizontal, 16)
      .frame(height: 30)
      .overlay {
        Text(title)
          .font(.chicagoRegular())
          .foregroundColor(.Pod.displayBlack)
      }
      
      Rectangle()
        .fill(Color.Pod.displayBlack)
        .frame(height: 3)
    }
    .padding(.top, 4)
    .background(Color.Pod.displayWhite)
  }
  
  private var trackStatusView: some View {
    Group {
      if let status {
        Image(status == .playing ? .playStatus : .pauseStatus)
          .renderingMode(.template)
          .resizable()
          .foregroundColor(.Pod.displayBlack)
      }
    }
    .frame(width: 20, height: 20)
  }
}

#Preview {
  DisplayHeaderView(title: "iPod")
}
