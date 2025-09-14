import Foundation

struct MenuItemTree: Equatable {
  let root: MenuItem
  
  init(root: MenuItem) {
    self.root = root
  }
  
  // MARK: - Search
  
  func searchItems(query: String) -> [MenuItem] {
    return searchInItems([root], query: query.lowercased())
  }
  
  private func searchInItems(_ items: [MenuItem], query: String) -> [MenuItem] {
    var results: [MenuItem] = []
    
    for item in items {
      if item.title.lowercased().contains(query) {
        results.append(item)
      }
      
      if !item.children.isEmpty {
        results.append(contentsOf: searchInItems(item.children, query: query))
      }
    }
    
    return results
  }
}


// MARK: - Tree Building

extension MenuItemTree {
  
  static func createDefaultTree() -> MenuItemTree {
    let root = MenuItem(
      title: "iPod",
      type: .folder,
      children: [
        MenuItem(
          title: "Playlists",
          type: .folder,
          children: []
        ),
        MenuItem(
          title: "Artists",
          type: .folder,
          children: []
        ),
        MenuItem(
          title: "Songs",
          type: .folder,
          children: []
        ),
        MenuItem(
          title: "Settings",
          type: .settings
        ),
      ]
    )
    
    return MenuItemTree(root: root)
  }
  
}
