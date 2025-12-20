import SwiftUI
import ComposableArchitecture

// MARK: - MenuView

struct MenuView: View {
  
  // MARK: - Properties
  
  let store: StoreOf<MenuFeature>
  
  // MARK: - Body
  
  var body: some View {
    
    WithPerceptionTracking {
      ZStack {
        ForEach(store.navigationPath, id: \.id) { item in
          MenuPageView(
            items: item.children,
            selectedIndex: store.selectedIndex
          )
          .transition(.slide)
        }
      }
    }
  }
}

// MARK: - MenuPageView

struct MenuPageView: View {
  
  // MARK: - Properties
  
  let items: [MenuItem]
  let selectedIndex: Int
  let visibleCount: Int = 6
  
  @State private var startIndex: Int = 0
  
  // MARK: - Computed Properties
  
  private var endIndex: Int {
    min(startIndex + visibleCount, items.count)
  }
  
  private var currentPage: [MenuItem] {
    Array(items[startIndex..<endIndex])
  }
  
  // MARK: - Body
  
  var body: some View {
    VStack(spacing: 0) {
      ForEach(currentPage.indices, id: \.self) { i in
        let globalIndex = startIndex + i
        MenuItemView(
          text: items[globalIndex].title,
          isSelected: selectedIndex == globalIndex
        )
        .transition(.identity)
      }
    }
    .onChange(of: selectedIndex) { newIndex in
      handleScroll(for: newIndex)
    }
  }
  
  // MARK: - Private Methods
  
  private func handleScroll(for index: Int) {
    guard items.count > visibleCount else { return }
    
    // Скролл вниз (если выбранный элемент уходит за нижний край)
    if index >= endIndex {
      startIndex = min(startIndex + 1, items.count - visibleCount)
    }
    // Скролл вверх (если выбранный элемент уходит за верхний край)
    else if index < startIndex {
      startIndex = max(startIndex - 1, 0)
    }
  }
}
