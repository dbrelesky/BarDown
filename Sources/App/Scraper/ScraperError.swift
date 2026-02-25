import Vapor

/// Errors that can occur during scraping operations.
enum ScraperError: Error, CustomStringConvertible {
    case networkError(String)
    case parseError(String)
    case emptyResponse
    case rateLimited
    case unknownConference(String)

    var description: String {
        switch self {
        case .networkError(let detail):
            return "Network error: \(detail)"
        case .parseError(let detail):
            return "Parse error: \(detail)"
        case .emptyResponse:
            return "Empty response from data source"
        case .rateLimited:
            return "Rate limited by data source"
        case .unknownConference(let conf):
            return "Unknown conference: \(conf)"
        }
    }
}
