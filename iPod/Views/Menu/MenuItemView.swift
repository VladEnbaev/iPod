import SwiftUI

struct MenuItemView: View {
  
  // MARK: - Parameters
  
  let text: String
  let isSelected: Bool
  
  // MARK: - Private Parameters
  
  private var foregroundColor: Color {
    isSelected ? .Pod.displayWhite : .Pod.displayBlack
  }
  
  private var backgroundColor: Color {
    isSelected ? .Pod.displayBlack : .Pod.displayWhite
  }
  
  // MARK: - Body
  
  var body: some View {
    HStack(spacing: .zero) {
      Text(text)
        .font(.chicagoRegular())
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
    .background(backgroundColor)
  }
}

#Preview {
  MenuItemView(text: "Settings", isSelected: true)
    .frame(width: 250)
}
