import SwiftUI

struct MenuRow: View {
  
  let text: String
  let isSelected: Bool
  
  var foregroundColor: Color {
    isSelected ? .Pod.displayWhite : .Pod.displayBlack
  }
  
  var body: some View {
    HStack(spacing: .zero) {
      Text(text)
        .font(.chicagoRegular(size: 22))
        .foregroundColor(foregroundColor)
        .frame(maxWidth: .infinity, alignment: .leading)
      Image(.arrowRight)
        .resizable()
        .renderingMode(.template)
        .frame(width: 18, height: 18)
        .foregroundColor(foregroundColor)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 5)
    .frame(height: 30)
    .background(isSelected ? Color.Pod.displayBlack : .Pod.displayWhite)
  }
}

#Preview {
  MenuRow(text: "Settings", isSelected: true)
    .frame(width: 250)
}
