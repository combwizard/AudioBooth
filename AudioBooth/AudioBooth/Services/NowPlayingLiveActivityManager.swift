import API
import Foundation
import Logging
import Models
import Nuke
import PlayerIntents
import SwiftUI

#if !targetEnvironment(macCatalyst)
import ActivityKit
#endif

@MainActor
final class NowPlayingLiveActivityManager {
  static let shared = NowPlayingLiveActivityManager()

  #if !targetEnvironment(macCatalyst)
  private var activity: Activity<NowPlayingActivityAttributes>?
  #endif
  private var currentBookID: String?
  private var coverCacheTask: Task<Void, Never>?

  private init() {}

  func update(
    playbackState: PlaybackState,
    chapterTitle: String?,
    accentColor: Color?,
    enabled: Bool
  ) {
    #if targetEnvironment(macCatalyst)
    return
    #else
    guard enabled else {
      end()
      return
    }

    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      AppLogger.player.debug("Live Activities not enabled")
      return
    }

    let subtitle = chapterTitle
    let contentState = NowPlayingActivityAttributes.ContentState(
      currentTime: playbackState.currentTime,
      duration: playbackState.duration,
      isPlaying: playbackState.isPlaying,
      playbackSpeed: playbackState.playbackSpeed,
      chapterTitle: subtitle,
      accentColor: accentColor
    )

    if currentBookID != playbackState.bookID {
      end()
      currentBookID = playbackState.bookID
      cacheCover(from: playbackState.coverURL, bookID: playbackState.bookID) { [weak self] coverFilename in
        self?.startActivity(
          playbackState: playbackState,
          coverFilename: coverFilename,
          contentState: contentState
        )
      }
    } else if activity != nil {
      updateActivity(contentState)
    } else {
      let coverFilename = existingCoverFilename(for: playbackState.bookID)
      startActivity(
        playbackState: playbackState,
        coverFilename: coverFilename,
        contentState: contentState
      )
    }
    #endif
  }

  func end() {
    #if !targetEnvironment(macCatalyst)
    coverCacheTask?.cancel()
    coverCacheTask = nil

    guard let activity else {
      currentBookID = nil
      return
    }

    Task {
      await activity.end(nil, dismissalPolicy: .immediate)
      AppLogger.player.info("Now Playing Live Activity ended")
    }
    self.activity = nil
    currentBookID = nil
    #endif
  }

  #if !targetEnvironment(macCatalyst)
  private func startActivity(
    playbackState: PlaybackState,
    coverFilename: String?,
    contentState: NowPlayingActivityAttributes.ContentState
  ) {
    let attributes = NowPlayingActivityAttributes(
      bookID: playbackState.bookID,
      title: playbackState.title,
      author: playbackState.author,
      coverFilename: coverFilename
    )

    let staleDate = contentState.isPlaying ? Date().addingTimeInterval(15) : nil

    do {
      activity = try Activity.request(
        attributes: attributes,
        content: .init(state: contentState, staleDate: staleDate),
        pushType: nil
      )
      AppLogger.player.info("Now Playing Live Activity started")
    } catch {
      AppLogger.player.error("Failed to start Now Playing Live Activity: \(error)")
    }
  }

  private func updateActivity(_ contentState: NowPlayingActivityAttributes.ContentState) {
    guard let activity else { return }

    let staleDate = contentState.isPlaying ? Date().addingTimeInterval(15) : nil
    Task {
      await activity.update(.init(state: contentState, staleDate: staleDate))
    }
  }

  private func existingCoverFilename(for bookID: String) -> String? {
    let fileURL = Self.coverFileURL(bookID: bookID)
    return FileManager.default.fileExists(atPath: fileURL.path) ? "\(bookID).jpg" : nil
  }

  private func cacheCover(from url: URL?, bookID: String, completion: @escaping (String?) -> Void) {
    coverCacheTask?.cancel()

    guard let url else {
      completion(nil)
      return
    }

    coverCacheTask = Task { @MainActor in
      let filename = await Self.downloadCover(from: url, bookID: bookID)
      guard !Task.isCancelled else { return }
      completion(filename)
    }
  }

  private static var coversDirectory: URL {
    DownloadManager.appGroupContainer.appendingPathComponent("liveActivityCovers", isDirectory: true)
  }

  private static func coverFileURL(bookID: String) -> URL {
    coversDirectory.appendingPathComponent("\(bookID).jpg")
  }

  private static func downloadCover(from url: URL, bookID: String) async -> String? {
    var thumbnailURL = url
    if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
      components.query = "width=200"
      thumbnailURL = components.url ?? url
    }

    do {
      try FileManager.default.createDirectory(at: coversDirectory, withIntermediateDirectories: true)

      let request = ImageRequest(url: thumbnailURL)
      let image = try await ImagePipeline.shared.image(for: request)

      guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }

      let fileURL = coverFileURL(bookID: bookID)
      try data.write(to: fileURL, options: .atomic)
      return "\(bookID).jpg"
    } catch {
      AppLogger.player.debug("Failed to cache Live Activity cover: \(error.localizedDescription)")
      return nil
    }
  }
  #endif
}

extension NowPlayingLiveActivityManager {
  #if !targetEnvironment(macCatalyst)
  static func endAllActivities() async {
    for activity in Activity<NowPlayingActivityAttributes>.activities {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
  }
  #else
  static func endAllActivities() async {}
  #endif
}
