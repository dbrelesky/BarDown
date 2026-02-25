import Foundation

enum GameEndpoint {
    case gamesForDate(Date)
    case availableDates(from: Date, to: Date)

    private static let easternFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "America/New_York")!
        return f
    }()

    func url(baseURL: URL) -> URL {
        switch self {
        case .gamesForDate(let date):
            let dateString = Self.easternFormatter.string(from: date)
            return baseURL.appendingPathComponent("/api/v1/games/date/\(dateString)")

        case .availableDates(let from, let to):
            let fromString = Self.easternFormatter.string(from: from)
            let toString = Self.easternFormatter.string(from: to)
            var components = URLComponents(
                url: baseURL.appendingPathComponent("/api/v1/games/dates"),
                resolvingAgainstBaseURL: false
            )!
            components.queryItems = [
                URLQueryItem(name: "from", value: fromString),
                URLQueryItem(name: "to", value: toString)
            ]
            return components.url!
        }
    }
}
