import Foundation

@MainActor
final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL
    private let apiKey: String

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        self.session = .shared
        let baseURLString = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String ?? ""
        self.baseURL = URL(string: baseURLString) ?? URL(string: "http://localhost:8080")!
        self.apiKey = Bundle.main.object(forInfoDictionaryKey: "APIKey") as? String ?? ""
    }

    func fetchGames(for date: Date) async throws -> [GameModel] {
        let url = GameEndpoint.gamesForDate(date).url(baseURL: baseURL)
        return try await fetch([GameModel].self, from: url)
    }

    func fetchAvailableDates(from: Date, to: Date) async throws -> [String] {
        let url = GameEndpoint.availableDates(from: from, to: to).url(baseURL: baseURL)
        return try await fetch([String].self, from: url)
    }

    private func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        var request = URLRequest(url: url)
        if !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode(type, from: data)
    }
}
