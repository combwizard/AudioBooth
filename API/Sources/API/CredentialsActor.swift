import Foundation

actor CredentialsActor {
  private var refreshTask: Task<Credentials, Error>?
  private weak var server: Server?

  private var consecutiveFailures: Int = 0
  private var nextRetryAt: Date?

  init(server: Server) {
    self.server = server
  }

  var freshCredentials: Credentials {
    get async throws {
      if let refreshTask {
        return try await refreshTask.value
      }

      guard let server else {
        throw Audiobookshelf.AudiobookshelfError.networkError("No server")
      }

      guard case .bearer(_, let refreshToken, let expiresAt) = server.token else {
        return server.token
      }

      let currentTime = Date().timeIntervalSince1970
      let bufferTime: TimeInterval = 60

      if currentTime < (expiresAt - bufferTime) {
        return server.token
      }

      if refreshToken.isEmpty {
        throw Audiobookshelf.AudiobookshelfError.networkError(
          "Refresh token is no longer valid, re-authentication required"
        )
      }

      if let nextRetryAt, Date() < nextRetryAt {
        throw Audiobookshelf.AudiobookshelfError.networkError(
          "Token refresh temporarily unavailable, retrying later"
        )
      }

      let task = Task<Credentials, Error> { @MainActor [server] in
        try await Audiobookshelf.shared.authentication.refreshToken(for: server)
      }

      refreshTask = task

      do {
        let credentials = try await task.value
        refreshTask = nil
        consecutiveFailures = 0
        nextRetryAt = nil
        return credentials
      } catch {
        refreshTask = nil
        await handleError(error)
        throw error
      }
    }
  }

  private func handleError(_ error: Error) async {
    if case NetworkError.httpError(let statusCode, _) = error,
      statusCode == 401 || statusCode == 403
    {
      consecutiveFailures = 0
      nextRetryAt = nil
      await MainActor.run { [weak server] in
        guard let server else { return }
        let cleared = Credentials.bearer(accessToken: "", refreshToken: "", expiresAt: 0)
        Audiobookshelf.shared.authentication.updateToken(server.id, token: cleared)
        server.status = .authenticationError
      }
      return
    }

    consecutiveFailures += 1
    let delay = min(60, pow(2.0, Double(consecutiveFailures)))
    nextRetryAt = Date().addingTimeInterval(delay)
  }
}
