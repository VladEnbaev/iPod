import SwiftUI

// MARK: - MenuPageView

struct MenuPageView: View {
  
  // MARK: - Properties
  
  let items: [MenuItem]
  let visibleCount: Int = 6
  let isActive: Bool
  let onSelect: (UUID) -> Void
  
  @State private var selectedIndex: Int = 0
  @State private var firstVisibleIndex: Int = 0
  
  // MARK: - Computed Properties
  
  private var lastVisibleIndex: Int {
    min(firstVisibleIndex + visibleCount, items.count)
  }
  
  private var currentPage: [MenuItem] {
    guard !items.isEmpty,
          firstVisibleIndex < items.count,
          lastVisibleIndex > 0 else {
      return []
    }
    return Array(items[firstVisibleIndex..<lastVisibleIndex])
  }
  
  // MARK: - Body
  
  var body: some View {
    HStack(spacing: .zero) {
      VStack(spacing: .zero) {
        // Список элементов
        ForEach(0..<currentPage.count, id: \.self) { i in
          let globalIndex = firstVisibleIndex + i
          MenuItemView(
            text: items[globalIndex].title,
            isSelected: selectedIndex == globalIndex
          )
        }
      }
      .padding(.top, 4)
      .padding(.horizontal, 1)
      
      if items.count > visibleCount {
        scrollIndicator
      }
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.Pod.displayWhite)
    .onReceive(ScrollWheelEventsPublisher.shared.events) { event in
      guard isActive else { return }
      
      switch event {
      case let .scrolled(direction):
        handleScroll(for: direction)
      case let .buttonPressed(button):
        guard button == .center else { return }
        onSelect(items[selectedIndex].id)
      }
    }
  }
  
  // MARK: - Scroll Indicator
  
  private var scrollIndicator: some View {
    Group {
      let width: CGFloat = 18
      
      GeometryReader { geometry in
        let height = geometry.size.height
        let heightRatio = CGFloat(visibleCount) / CGFloat(items.count)
        let offsetRatio = CGFloat(min(selectedIndex, items.count - visibleCount)) / CGFloat(items.count)
        
        Rectangle()
          .fill(Color.Pod.displayBlack)
          .clipShape(.rect(cornerRadius: 1))
          .padding(3)
          .frame(height: height * heightRatio)
          .offset(y: height * offsetRatio)
      }
      .frame(width: width, alignment: .center)
      .background(Color.Pod.displayWhite)
      .border(Color.Pod.displayBlack, width: 2)
    }
  }
}

// MARK: - Private Methods

private extension MenuPageView {
  
  private func handleScroll(for direction: WheelScrollDirection) {
    // Если прокрутили колесо назад, но выбранный индекс первый - выходим
    guard !(direction == .left && selectedIndex == 0) else { return }
    
    // Если прокрутили колесо вперед, но выбранный индекс последний - выходим
    guard !(direction == .right && selectedIndex == items.count - 1) else { return }
    
    selectedIndex += direction == .left ? -1 : 1
    
    // Если ячеек больше, чем влезает на экранчик - нужно скроллить экран
    guard items.count > visibleCount else { return }
    
    // Скролл вниз (если выбранный элемент уходит за нижний край)
    if selectedIndex >= lastVisibleIndex {
      firstVisibleIndex = min(firstVisibleIndex + 1, items.count - visibleCount)
      
    // Скролл вверх (если выбранный элемент уходит за верхний край)
    } else if selectedIndex < firstVisibleIndex {
      firstVisibleIndex = max(firstVisibleIndex - 1, 0)
    }
  }
}
