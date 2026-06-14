import Foundation
import SwiftUI
import UIKit

#if !targetEnvironment(macCatalyst)
import ActivityKit
#endif

#if !targetEnvironment(macCatalyst)
public struct NowPlayingActivityAttributes: ActivityAttributes {
  public let bookID: String
  public let title: String
  public let author: String
  public let coverFilename: String?

  public struct ContentState: Codable, Hashable {
    public var currentTime: TimeInterval
    public var duration: TimeInterval
    public var isPlaying: Bool
    public var playbackSpeed: Float
    public var updatedAt: Date
    public var chapterTitle: String?
    private var accentColorRaw: String?

    public init(
      currentTime: TimeInterval,
      duration: TimeInterval,
      isPlaying: Bool,
      playbackSpeed: Float,
      updatedAt: Date = Date(),
      chapterTitle: String? = nil,
      accentColor: Color? = nil
    ) {
      self.currentTime = currentTime
      self.duration = duration
      self.isPlaying = isPlaying
      self.playbackSpeed = playbackSpeed
      self.updatedAt = updatedAt
      self.chapterTitle = chapterTitle
      self.accentColorRaw = accentColor?.rawValue
    }

    public var accentColor: Color? {
      guard let raw = accentColorRaw else { return nil }
      return Color(rawValue: raw)
    }

    public var progress: Double {
      guard duration > 0 else { return 0 }
      return min(effectiveCurrentTime / duration, 1)
    }

    public var effectiveCurrentTime: TimeInterval {
      guard isPlaying else { return currentTime }
      let elapsed = Date().timeIntervalSince(updatedAt)
      return min(currentTime + elapsed * Double(playbackSpeed), duration)
    }

    public var timeRemaining: TimeInterval {
      max(duration - effectiveCurrentTime, 0)
    }
  }

  public init(bookID: String, title: String, author: String, coverFilename: String?) {
    self.bookID = bookID
    self.title = title
    self.author = author
    self.coverFilename = coverFilename
  }
}
#endif
