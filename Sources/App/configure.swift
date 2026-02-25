import Fluent
import FluentPostgresDriver
import Vapor

func configure(_ app: Application) async throws {
    // MARK: - Database Configuration

    if let databaseURL = Environment.get("DATABASE_URL") {
        // Railway provides DATABASE_URL as a connection string
        try app.databases.use(
            .postgres(url: databaseURL),
            as: .psql
        )
    } else {
        // Fall back to individual environment variables (local dev)
        let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
        let port = Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 5432
        let username = Environment.get("DATABASE_USERNAME") ?? "vapor"
        let password = Environment.get("DATABASE_PASSWORD") ?? "vapor"
        let database = Environment.get("DATABASE_NAME") ?? "bardown"

        let config = SQLPostgresConfiguration(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: .disable
        )
        app.databases.use(
            .postgres(configuration: config),
            as: .psql
        )
    }

    // MARK: - Migrations (dependency order)

    app.migrations.add(CreateConference())
    app.migrations.add(CreateTeam())
    app.migrations.add(CreatePlayer())
    app.migrations.add(CreateGame())
    app.migrations.add(CreateQuarterScore())
    app.migrations.add(CreateGameStats())
    app.migrations.add(CreatePlayerGameStats())
    app.migrations.add(SeedConferences())

    // MARK: - Auto-migrate (runs pending migrations on boot)

    try await app.autoMigrate()

    // MARK: - Routes
    // Note: API_KEY env var must be set in production (Railway environment variables).
    // When unset, API key middleware allows all traffic (development mode).

    try routes(app)

    // MARK: - Scraper Scheduler (skip in test environment)

    if app.environment != .testing {
        let scheduler = ScraperScheduler(app: app)
        Task {
            await scheduler.start()
        }
    }
}
