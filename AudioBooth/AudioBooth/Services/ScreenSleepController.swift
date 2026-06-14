import UIKit

enum ScreenSleepController {
  static func refresh() {
    let preferences = UserPreferences.shared
    let playerManager = PlayerManager.shared

    guard preferences.keepScreenAwakeInPlayer else {
      UIApplication.shared.isIdleTimerDisabled = false
      return
    }

    let shouldPreventSleep = playerManager.isShowingFullPlayer || playerManager.isPlaying
    UIApplication.shared.isIdleTimerDisabled = shouldPreventSleep
  }
}
