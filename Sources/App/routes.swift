import Vapor

func routes(_ app: Application) throws {
    // Health endpoint remains unauthenticated for Railway health checks.
    app.get("health") { req async -> [String: String] in
        ["status": "ok"]
    }

    // All /api/v1/* endpoints are protected by rate limiting (outer) and API key auth (inner).
    // Rate limiting runs first so abusive clients are rejected before key validation.
    let protected = app.grouped(RateLimitMiddleware()).grouped(APIKeyMiddleware())

    try protected.register(collection: GameController())
    try protected.register(collection: TeamController())
}
