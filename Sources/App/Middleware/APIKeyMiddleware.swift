import NIOConcurrencyHelpers
import Vapor

/// Middleware that validates the `X-API-Key` request header against the `API_KEY` environment variable.
///
/// - When `API_KEY` is **not set** (local development), all requests pass through with a logged warning.
/// - When `API_KEY` **is set**, requests missing the header or providing a wrong value receive 401 Unauthorized.
struct APIKeyMiddleware: AsyncMiddleware {

    /// Tracks whether the "no API_KEY configured" warning has been logged to avoid log spam.
    private static let warnedOnce = NIOLockedValueBox(false)

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let expectedKey = Environment.get("API_KEY") else {
            // Development fallback -- allow all traffic but warn once.
            Self.warnedOnce.withLockedValue { warned in
                if !warned {
                    request.logger.warning("API_KEY environment variable is not set. All requests are allowed (development mode).")
                    warned = true
                }
            }
            return try await next.respond(to: request)
        }

        guard let providedKey = request.headers.first(name: "X-API-Key"),
              providedKey == expectedKey else {
            throw Abort(.unauthorized, reason: "Invalid or missing API key")
        }

        return try await next.respond(to: request)
    }
}
