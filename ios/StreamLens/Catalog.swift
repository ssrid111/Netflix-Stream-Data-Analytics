import Foundation

struct CatalogTitle: Codable, Identifiable {
    let id: String
    let title: String
    let type: String
    let releaseYear: Int
    let country: String
    let genres: String
    let rating: String
    var countries: [String] { country.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
    var genreList: [String] { genres.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
}
struct CatalogGroup: Identifiable { let name: String; let count: Int; var id: String { name } }
enum CatalogError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case .invalid(let message) = self { return message }; return nil }
}
enum CSVReader {
    static func rows(_ source: String) throws -> [[String]] {
        var rows: [[String]] = [], row: [String] = [], field = "", quoted = false
        let chars = Array(source.replacingOccurrences(of: "\u{FEFF}", with: ""))
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c == "\"" {
                if quoted && i + 1 < chars.count && chars[i+1] == "\"" { field.append("\""); i += 1 }
                else { quoted.toggle() }
            } else if c == "," && !quoted { row.append(field); field = "" }
            else if (c == "\n" || c == "\r" || c == "\r\n") && !quoted {
                row.append(field); if row.contains(where: { !$0.isEmpty }) { rows.append(row) }; row = []; field = ""
                if c == "\r" && i+1 < chars.count && chars[i+1] == "\n" { i += 1 }
            } else { field.append(c) }
            i += 1
        }
        guard !quoted else { throw CatalogError.invalid("The CSV has an unclosed quoted field.") }
        if !field.isEmpty || !row.isEmpty { row.append(field); rows.append(row) }
        return rows
    }
    static func catalog(_ source: String) throws -> [CatalogTitle] {
        let table = try rows(source)
        guard let headers = table.first?.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }),
              ["title", "type", "release_year"].allSatisfy({ headers.contains($0) }) else {
            throw CatalogError.invalid("CSV needs title, type, and release_year columns. Optional: country, listed_in, rating, show_id.")
        }
        var result: [CatalogTitle] = []
        for (index, row) in table.dropFirst().enumerated() {
            func value(_ key: String) -> String { guard let position = headers.firstIndex(of: key), position < row.count else { return "" }; return row[position].trimmingCharacters(in: .whitespacesAndNewlines) }
            guard !value("title").isEmpty, let year = Int(value("release_year")), (1880...2100).contains(year), ["Movie", "TV Show"].contains(value("type")) else { continue }
            result.append(CatalogTitle(id: "row-\(index)", title: value("title"), type: value("type"), releaseYear: year,
                                       country: value("country"), genres: value("listed_in"), rating: value("rating")))
        }
        guard !result.isEmpty else { throw CatalogError.invalid("No valid titles found. Check type values (Movie / TV Show) and release years.") }
        return result
    }
}
enum CatalogAnalytics {
    static func groups(_ rows: [CatalogTitle], values: (CatalogTitle) -> [String]) -> [CatalogGroup] {
        var counts: [String: Int] = [:]
        for row in rows { for value in Set(values(row)) where !value.isEmpty { counts[value, default: 0] += 1 } }
        return counts.map { CatalogGroup(name: $0.key, count: $0.value) }.sorted { $0.count == $1.count ? $0.name < $1.name : $0.count > $1.count }
    }
}
