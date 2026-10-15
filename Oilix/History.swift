import Foundation
import SwiftUI
import MapKit
import Alamofire

struct sampleHist: Identifiable {
    var id: String { serverID.map(String.init) ?? path }
    let date: Date
    let locat: CLLocationCoordinate2D?
    let result: String
    let notes: String
    let disperseX: Double
    let disperseY: Double
    let path: String
    let tags: String
    var serverID: Int? = nil
    var username: String? = nil

    var displayTitle: String {
        let note = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return note.isEmpty ? serverID.map { "Sample #\($0)" } ?? "Sample" : note
    }
}

enum HistoryScope: String, CaseIterable {
    case all, mine

    var title: String { self == .all ? "All Samples" : "My Samples" }
}

struct HistoryResponseFail: Decodable { let status: Int; let msg: String }

struct HistoryResponse: Decodable {
    let status: Int
    struct HistoryRecord: Decodable {
        let id: Int?
        let path: String
        let gps: String
        let date: String
        let result: String?
        let notes: String
        let tags: String?
        let username: String?
    }
    let msg: [Int: HistoryRecord]
    struct HistoryMeta: Decodable {
        let total_page: Int
        let current_page: Int
        let attempted_username: String
    }
    let meta: HistoryMeta
}

class History: ObservableObject {
    @Published var data = [sampleHist]()
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var scope: HistoryScope
    let canViewAllSamples: Bool
    private let network: Alamofire.Session

    init(network: Alamofire.Session = .default, isAdmin: Bool = false) {
        self.network = network
        canViewAllSamples = isAdmin
        scope = isAdmin ? .all : .mine
    }

    func selectScope(_ scope: HistoryScope, completion: (() -> Void)? = nil) {
        guard !isLoading, scope != self.scope, scope != .all || canViewAllSamples else {
            completion?()
            return
        }
        self.scope = scope
        // A failed scope change must not display records from the previous scope.
        data = []
        errorMessage = nil
        getHistory(completion: completion)
    }

    static func getLocation(locStr: String) -> CLLocationCoordinate2D? {
        let parts = locStr.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let latitude = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let longitude = Double(parts[1].trimmingCharacters(in: .whitespaces)) else { return nil }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return CLLocationCoordinate2DIsValid(coordinate) ? coordinate : nil
    }

    func getHistory(completion: (() -> Void)? = nil) {
        guard !isLoading else { completion?(); return }
        isLoading = true
        errorMessage = nil
        fetch(page: 1, accumulated: [], completion: completion)
    }

    func getFromServer(completion: (() -> Void)? = nil) { getHistory(completion: completion) }

    private func fetch(page: Int, accumulated: [HistoryResponse.HistoryRecord], completion: (() -> Void)?) {
        // Publish a complete snapshot so search and same-day ordering cover every server page.
        var parameters = ["page": String(page)]
        if scope == .all { parameters.merge(["mindate": "-", "maxdate": "-"]) { _, new in new } }
        let endpoint = scope == .all ? "adminphotolist" : "history"
        network.request(serverURL + endpoint, method: .post, parameters: parameters,
                        encoder: URLEncodedFormParameterEncoder(destination: .httpBody)) { $0.timeoutInterval = 20 }
            .validate(statusCode: 200..<300)
            .responseData { response in
                guard case .success(let data) = response.result else {
                    let message = self.data.isEmpty
                        ? "History could not be loaded. Check your connection and try again."
                        : "History could not be refreshed. Previously loaded records are still available."
                    self.finish(error: message, completion: completion)
                    return
                }
                let decoder = JSONDecoder()
                if let failure = try? decoder.decode(HistoryResponseFail.self, from: data), failure.status != 0 {
                    self.finish(error: failure.msg, completion: completion); return
                }
                guard let decoded = try? decoder.decode(HistoryResponse.self, from: data), decoded.status == 0,
                      decoded.meta.current_page == page, (1...10000).contains(decoded.meta.total_page) else {
                    self.finish(error: "History could not be read. Please try again.", completion: completion); return
                }
                let records = accumulated + Array(decoded.msg.values)
                if page < decoded.meta.total_page && !decoded.msg.isEmpty {
                    self.fetch(page: page + 1, accumulated: records, completion: completion)
                    return
                }
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "yyyy-MM-dd"
                var seen = Set<String>()
                self.data = records.sorted {
                    $0.date == $1.date ? ($0.id ?? 0) > ($1.id ?? 0) : $0.date > $1.date
                }.compactMap { record in
                    let key = record.id.map(String.init) ?? record.path
                    guard seen.insert(key).inserted, let date = formatter.date(from: record.date) else { return nil }
                    let seed = abs((record.id ?? record.path.hashValue) % 1000)
                    return sampleHist(date: date, locat: Self.getLocation(locStr: record.gps),
                                      result: record.result ?? "", notes: record.notes,
                                      disperseX: Double(seed % 17 - 8) * 0.00008,
                                      disperseY: Double(seed % 19 - 9) * 0.00008,
                                      path: record.path, tags: record.tags ?? "", serverID: record.id,
                                      username: record.username)
                }
                self.finish(error: nil, completion: completion)
            }
    }

    private func finish(error: String?, completion: (() -> Void)?) {
        errorMessage = error
        isLoading = false
        completion?()
    }
}
