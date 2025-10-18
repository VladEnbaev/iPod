import Foundation

// MARK: - Menu Item Types

enum MenuItemType: Equatable {
  case folder
  case track
  case playlist
  case artist
  case album
  case settings
}

// MARK: - Menu Item

struct MenuItem: Identifiable, Equatable {
  var id = UUID()
  var title: String
  var type: MenuItemType
  var children: [MenuItem]
  var metadata: MenuItemMetadata?
  
  init(
    title: String,
    type: MenuItemType,
    children: [MenuItem] = [],
    metadata: MenuItemMetadata? = nil
  ) {
    self.title = title
    self.type = type
    self.children = children
    self.metadata = metadata
  }
}

// MARK: - Menu Item Metadata

struct MenuItemMetadata: Equatable {
  var duration: TimeInterval?
  var artist: String?
  var album: String?
  var artwork: String?
  var trackNumber: Int?
  var year: Int?
  
  init(
    duration: TimeInterval? = nil,
    artist: String? = nil,
    album: String? = nil,
    artwork: String? = nil,
    trackNumber: Int? = nil,
    year: Int? = nil
  ) {
    self.duration = duration
    self.artist = artist
    self.album = album
    self.artwork = artwork
    self.trackNumber = trackNumber
    self.year = year
  }
}

// MARK: - Extensions

extension MenuItem {
  var hasChildren: Bool {
    !children.isEmpty
  }
  
  var isPlayable: Bool {
    type == .track || type == .playlist
  }
  
  var displayTitle: String {
    switch type {
    case .track:
      if let trackNumber = metadata?.trackNumber {
        return "\(trackNumber). \(title)"
      }
      return title
    default:
      return title
    }
  }
  
  var subtitle: String? {
    switch type {
    case .track:
      return metadata?.artist
    case .album:
      return metadata?.artist
    case .artist:
      return "Artist"
    default:
      return nil
    }
  }
}
