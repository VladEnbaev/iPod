import Foundation

struct MenuItemTree: Equatable {
  var root: MenuItem
  
  init(root: MenuItem) {
    self.root = root
  }
  
  func getFolder(path: [Int]) -> MenuItem {
    path.reduce(root) { $0.children[$1] }
  }
  
  func getItems(path: [Int]) -> [MenuItem] {
    getFolder(path: path).children
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
