import SwiftUI
import ComposableArchitecture


// MARK: - MenuView

struct MenuView: View {
  
  var store: StoreOf<MenuFeature>
  
  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        ZStack {
          MenuPageView(
            items: store.currentFolder.children,
            selectedIndex: store.selectedIndex
          )
          
          ForEach(store.pathIndices, id: \.self) { i in
            if i == store.pathIndices.count - 1 {
              MenuPageView(
                items: store.currentFolder.children,
                selectedIndex: store.selectedIndex
              )
              .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
              ))
            }
          }
          
          //      .transition(.slide)
          .animation(.easeInOut(duration: 0.2), value: store.pathIndices)
        }
      }
    }
  }
}



// MARK: - MenuPageView

struct MenuPageView: View {
  let items: [MenuItem]
  let selectedIndex: Int
  let visibleCount: Int = 6

  @State private var startIndex: Int = 0
  
  private var endIndex: Int {
    min(startIndex + visibleCount, items.count)
  }
  
  private var currentPage: [MenuItem] {
    Array(items[startIndex..<endIndex])
  }
  
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
//    .animation(
//      selectedIndex <= startIndex || selectedIndex >= endIndex
//      ? nil
//      : .easeInOut(duration: 0.25),
//      value: selectedIndex
//    )
  }
  
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
