import SwiftUI

/// Расширение с методами для добавления шрифтов с выбором размера
extension Font {
  
  public static func chicagoRegular(size: CGFloat) -> Font {
    return Font.custom("Chicago", size: size)
  }
}

