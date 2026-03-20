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
  public var metadata: TrackInfo?
  
  public init(
    title: String,
    type: MenuItemType,
    children: [MenuItem] = [],
    metadata: TrackInfo? = nil
  ) {
    self.title = title
    self.type = type
    self.children = children
    self.metadata = metadata
  }
}

// MARK: - Track Info

public struct TrackInfo: Equatable {
  public let duration: TimeInterval
  public let artist: String?
  public let album: String?
  public let artwork: Data?
  public let trackNumber: Int?
  public let year: Int?
  public let fileURL: URL
  
  public init(
    duration: TimeInterval,
    artist: String? = nil,
    album: String? = nil,
    artwork: Data? = nil,
    trackNumber: Int? = nil,
    year: Int? = nil,
    fileURL: URL
  ) {
    self.duration = duration
    self.artist = artist
    self.album = album
    self.artwork = artwork
    self.trackNumber = trackNumber
    self.year = year
    self.fileURL = fileURL
  }
}

// MARK: - Extensions

public extension MenuItem {
  var hasChildren: Bool {
    !children.isEmpty
  }
  
  var isPlayable: Bool {
    type == .track
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
