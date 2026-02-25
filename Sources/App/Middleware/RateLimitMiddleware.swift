import NIOConcurrencyHelpers
import Vapor

/// Per-IP rate limiting middleware using a fixed-window algorithm.
///
/// Allows up to `maxRequests` (default 100) requests per `windowSeconds` (default 60) per client IP.
/// Exceeding the limit returns **429 Too Many Requests** with a `Retry-After` header.
/// Stale entries are cleaned up periodically to prevent unbounded memory growth.
final class RateLimitMiddleware: AsyncMiddleware, @unchecked Sendable {

    // MARK: - Configuration

    private let maxRequests: Int
    private let windowSeconds: TimeInterval
    private let cleanupInterval: Int

    // MARK: - Shared State

    private struct Entry {
        var count: Int
        var windowStart: Date
    }

    private let store = NIOLockedValueBox<[String: Entry]>([:])
    private let requestCounter = NIOLockedValueBox<Int>(0)

    // MARK: - Init

    /// - Parameters:
    ///   - maxRequests: Maximum requests per window (default 100).
    ///   - windowSeconds: Window duration in seconds (default 60).
    ///   - cleanupInterval: Purge stale entries every N requests (default 100).
    init(maxRequests: Int = 100, windowSeconds: TimeInterval = 60, cleanupInterval: Int = 100) {
        self.maxRequests = maxRequests
        self.windowSeconds = windowSeconds
        self.cleanupInterval = cleanupInterval
    }

    // MARK: - Middleware

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let clientIP = request.peerAddress?.description ?? "unknown"
        let now = Date()

        // Periodic cleanup of stale entries.
        let shouldCleanup = requestCounter.withLockedValue { counter -> Bool in
            counter += 1
            if counter >= cleanupInterval {
                counter = 0
                return true
            }
            return false
        }

        if shouldCleanup {
            store.withLockedValue { entries in
                entries = entries.filter { _, entry in
                    now.timeIntervalSince(entry.windowStart) < windowSeconds
                }
            }
        }

        // Rate-limit check.
        let allowed = store.withLockedValue { entries -> Bool in
            var entry = entries[clientIP] ?? Entry(count: 0, windowStart: now)

            // Reset window if expired.
            if now.timeIntervalSince(entry.windowStart) >= windowSeconds {
                entry = Entry(count: 0, windowStart: now)
            }

            entry.count += 1
            entries[clientIP] = entry

            return entry.count <= maxRequests
        }

        guard allowed else {
            var headers = HTTPHeaders()
            headers.add(name: "Retry-After", value: "\(Int(windowSeconds))")
            throw Abort(.tooManyRequests, headers: headers, reason: "Rate limit exceeded. Try again later.")
        }

        return try await next.respond(to: request)
    }
}
