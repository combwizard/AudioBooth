import API
import ActivityKit
import AppIntents
import Models
import PlayerIntents
import SwiftUI
import WidgetKit

struct NowPlayingLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: NowPlayingActivityAttributes.self) { context in
      NowPlayingLockScreenView(context: context)
    } dynamicIsland: { context in
      let accentColor = context.state.accentColor ?? Color.accentColor

      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          NowPlayingCoverImage(
            coverFilename: context.attributes.coverFilename,
            bookID: context.attributes.bookID
          )
          .frame(width: 52, height: 52)
          .clipShape(RoundedRectangle(cornerRadius: 8))
        }

        DynamicIslandExpandedRegion(.trailing) {
          NowPlayingPlayPauseButton(isPlaying: context.state.isPlaying)
            .font(.title2)
            .foregroundStyle(accentColor)
        }

        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 4) {
            Text(context.state.chapterTitle ?? context.attributes.title)
              .font(.headline)
              .lineLimit(1)

            Text(context.state.chapterTitle != nil ? context.attributes.title : context.attributes.author)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)

            NowPlayingProgressBar(progress: context.state.progress, accentColor: accentColor)
              .frame(height: 4)

            Text(NowPlayingFormatting.timeRemaining(context.state))
              .font(.caption2)
              .foregroundStyle(.secondary)
              .monospacedDigit()
          }
        }
      } compactLeading: {
        NowPlayingCoverImage(
          coverFilename: context.attributes.coverFilename,
          bookID: context.attributes.bookID
        )
        .frame(width: 22, height: 22)
        .clipShape(RoundedRectangle(cornerRadius: 4))
      } compactTrailing: {
        if context.state.isPlaying {
          Image(systemName: "waveform")
            .foregroundStyle(accentColor)
            .font(.caption.bold())
        } else {
          Image(systemName: "pause.fill")
            .foregroundStyle(.secondary)
            .font(.caption.bold())
        }
      } minimal: {
        Image("audiobooth.fill")
          .foregroundStyle(accentColor)
      }
    }
  }
}

private struct NowPlayingLockScreenView: View {
  let context: ActivityViewContext<NowPlayingActivityAttributes>

  private var accentColor: Color {
    context.state.accentColor ?? Color.accentColor
  }

  var body: some View {
    HStack(spacing: 12) {
      NowPlayingCoverImage(
        coverFilename: context.attributes.coverFilename,
        bookID: context.attributes.bookID
      )
      .frame(width: 56, height: 56)
      .clipShape(RoundedRectangle(cornerRadius: 8))

      VStack(alignment: .leading, spacing: 6) {
        VStack(alignment: .leading, spacing: 2) {
          Text(context.state.chapterTitle ?? context.attributes.title)
            .font(.headline)
            .lineLimit(1)

          Text(context.state.chapterTitle != nil ? context.attributes.title : context.attributes.author)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        NowPlayingProgressBar(progress: context.state.progress, accentColor: accentColor)
          .frame(height: 5)

        HStack {
          Text(NowPlayingFormatting.timeRemaining(context.state))
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()

          Spacer()

          NowPlayingPlayPauseButton(isPlaying: context.state.isPlaying)
            .font(.title2)
            .foregroundStyle(accentColor)
        }
      }
    }
    .padding(.vertical, 4)
  }
}

private struct NowPlayingCoverImage: View {
  let coverFilename: String?
  let bookID: String

  var body: some View {
    Group {
      if let image = loadCoverImage() {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
      } else {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.gray.opacity(0.3))
          .overlay {
            Image(systemName: "book.fill")
              .foregroundStyle(.secondary)
          }
      }
    }
  }

  private func loadCoverImage() -> UIImage? {
    guard let coverFilename else { return nil }

    guard
      let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: AppIdentifiers.appGroup
      )
    else { return nil }

    let fileURL =
      container
      .appendingPathComponent("liveActivityCovers", isDirectory: true)
      .appendingPathComponent(coverFilename)

    return UIImage(contentsOfFile: fileURL.path)
  }
}

private struct NowPlayingProgressBar: View {
  let progress: Double
  let accentColor: Color

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(Color.secondary.opacity(0.25))

        Capsule()
          .fill(accentColor)
          .frame(width: geometry.size.width * progress)
      }
    }
  }
}

private struct NowPlayingPlayPauseButton: View {
  let isPlaying: Bool

  var body: some View {
    if isPlaying {
      Button(intent: PausePlaybackIntent()) {
        Image(systemName: "pause.circle.fill")
      }
      .buttonStyle(.plain)
    } else {
      Button(intent: ResumePlaybackIntent()) {
        Image(systemName: "play.circle.fill")
      }
      .buttonStyle(.plain)
    }
  }
}

private enum NowPlayingFormatting {
  static func timeRemaining(_ state: NowPlayingActivityAttributes.ContentState) -> String {
    var remaining = state.timeRemaining
    let adjustsWithSpeed =
      UserDefaults.appGroup.object(forKey: "timeRemainingAdjustsWithSpeed") as? Bool ?? true
    if adjustsWithSpeed, state.playbackSpeed > 0 {
      remaining /= Double(state.playbackSpeed)
    }

    let formatted = Duration.seconds(remaining).formatted(
      .units(allowed: [.hours, .minutes], width: .narrow)
    )
    return "\(formatted) left"
  }
}
