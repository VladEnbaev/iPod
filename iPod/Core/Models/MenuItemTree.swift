import Foundation

final class MenuItemTree {
  
  // MARK: - Private Parameters
  
  private var root: MenuItem
  private var index: [UUID: MenuItem] = [:]
  private var parentIndex: [UUID: UUID] = [:]
  
  // MARK: - Init
  
  init(root: MenuItem) {
    self.root = root
    buildIndex(from: root)
  }
  
  // MARK: - Public Methods
  
  func rootItem() -> MenuItem {
    root
  }
  
  func item(withId id: UUID) -> MenuItem? {
    index[id]
  }
  
  func children(of id: UUID?) -> [MenuItem] {
    guard let id, let item = index[id] else {
      return root.children
    }
    return item.children
  }
  
  func parent(of id: UUID) -> MenuItem? {
    guard let parentId = parentIndex[id] else { return nil }
    return index[parentId]
  }
  
  func add(items: [MenuItem], toFolderId id: UUID?) {
    if let id, var folder = index[id] {
      folder.children.append(contentsOf: items)
      for item in items {
        buildIndex(from: item, parentId: folder.id)
      }
      index[id] = folder
    } else {
      root.children.append(contentsOf: items)
      for item in items {
        buildIndex(from: item, parentId: root.id)
      }
    }
  }
}

// MARK: - Private Methods

private extension MenuItemTree {
  
  private func buildIndex(from node: MenuItem, parentId: UUID? = nil) {
    index[node.id] = node
    if let parentId {
      parentIndex[node.id] = parentId
    }
    for child in node.children {
      buildIndex(from: child, parentId: node.id)
    }
  }
}
