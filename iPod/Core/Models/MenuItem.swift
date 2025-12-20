import Foundation

// MARK: - Menu Item Types

public enum MenuItemType: Equatable {
  case folder
  case track
  case playlist
  case artist
  case album
  case settings
}

// MARK: - Menu Item

public struct MenuItem: Identifiable, Equatable {
  public var id = UUID()
  public var title: String
  public var type: MenuItemType
  public var children: [MenuItem]
  public var metadata: MenuItemMetadata?
  
  public init(
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

public struct MenuItemMetadata: Equatable {
  public var duration: TimeInterval?
  public var artist: String?
  public var album: String?
  public var artwork: String?
  public var trackNumber: Int?
  public var year: Int?
  
  public init(
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

public extension MenuItem {
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
