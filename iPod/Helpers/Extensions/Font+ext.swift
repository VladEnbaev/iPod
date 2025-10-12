import SwiftUI

/// Расширение с методами для добавления шрифтов с выбором размера
extension Font {
  
  public static func chicagoRegular(size: CGFloat = .commonFontSize) -> Font {
    return Font.custom("Chicago", size: size)
  }
}

extension CGFloat {
  public static let commonFontSize: CGFloat = 22
}
