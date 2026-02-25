@testable import App
import XCTVapor

final class APIKeyMiddlewareTests: XCTestCase {

    private func makeApp(apiKey: String? = nil) throws -> Application {
        let app = Application(.testing)
        if let apiKey = apiKey {
            setenv("API_KEY", apiKey, 1)
        } else {
            unsetenv("API_KEY")
        }

        let protected = app.grouped(APIKeyMiddleware())
        protected.get("test") { _ in "ok" }

        return app
    }

    override func tearDown() {
        unsetenv("API_KEY")
        super.tearDown()
    }

    func testValidAPIKey() throws {
        let app = try makeApp(apiKey: "test-secret-key")
        defer { app.shutdown() }

        try app.test(.GET, "test", headers: ["X-API-Key": "test-secret-key"]) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "ok")
        }
    }

    func testInvalidAPIKey() throws {
        let app = try makeApp(apiKey: "test-secret-key")
        defer { app.shutdown() }

        try app.test(.GET, "test", headers: ["X-API-Key": "wrong-key"]) { res in
            XCTAssertEqual(res.status, .unauthorized)
        }
    }

    func testMissingAPIKey() throws {
        let app = try makeApp(apiKey: "test-secret-key")
        defer { app.shutdown() }

        try app.test(.GET, "test") { res in
            XCTAssertEqual(res.status, .unauthorized)
        }
    }

    func testDevModeFallback() throws {
        let app = try makeApp(apiKey: nil)
        defer { app.shutdown() }

        try app.test(.GET, "test") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "ok")
        }
    }
}

final class RateLimitMiddlewareTests: XCTestCase {

    private func makeApp(maxRequests: Int = 3, windowSeconds: TimeInterval = 60) throws -> Application {
        let app = Application(.testing)

        let rateLimiter = RateLimitMiddleware(
            maxRequests: maxRequests,
            windowSeconds: windowSeconds,
            cleanupInterval: 1000
        )
        let protected = app.grouped(rateLimiter)
        protected.get("test") { _ in "ok" }

        return app
    }

    func testUnderLimit() throws {
        let app = try makeApp(maxRequests: 3)
        defer { app.shutdown() }

        for _ in 0..<3 {
            try app.test(.GET, "test") { res in
                XCTAssertEqual(res.status, .ok)
            }
        }
    }

    func testOverLimit() throws {
        let app = try makeApp(maxRequests: 3)
        defer { app.shutdown() }

        // First 3 should pass
        for _ in 0..<3 {
            try app.test(.GET, "test") { res in
                XCTAssertEqual(res.status, .ok)
            }
        }

        // 4th should be rate-limited
        try app.test(.GET, "test") { res in
            XCTAssertEqual(res.status, .tooManyRequests)
        }
    }

    func testRetryAfterHeader() throws {
        let app = try makeApp(maxRequests: 1, windowSeconds: 60)
        defer { app.shutdown() }

        // First passes
        try app.test(.GET, "test") { res in
            XCTAssertEqual(res.status, .ok)
        }

        // Second is rate-limited with Retry-After
        try app.test(.GET, "test") { res in
            XCTAssertEqual(res.status, .tooManyRequests)
            XCTAssertEqual(res.headers.first(name: "Retry-After"), "60")
        }
    }

    func testSeparateInstancesHaveSeparateState() throws {
        // Each app gets its own RateLimitMiddleware instance, so counters are separate
        let app1 = try makeApp(maxRequests: 1)
        defer { app1.shutdown() }

        let app2 = try makeApp(maxRequests: 1)
        defer { app2.shutdown() }

        try app1.test(.GET, "test") { res in
            XCTAssertEqual(res.status, .ok)
        }

        // app2 has its own limiter, should also pass
        try app2.test(.GET, "test") { res in
            XCTAssertEqual(res.status, .ok)
        }
    }
}
