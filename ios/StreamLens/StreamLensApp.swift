import SwiftUI
import Charts
import UniformTypeIdentifiers

@main
struct StreamLensApp: App { var body: some Scene { WindowGroup { CatalogHome() } } }
struct CatalogHome: View {
    @State private var rows: [CatalogTitle] = []
    @State private var search = ""
    @State private var type = "All"
    @State private var country = "All"
    @State private var minimumYear = 0
    @State private var importing = false
    @State private var error: String?
    @State private var source = "Illustrative sample · not Netflix's full catalog"
    private let red = Color(red: 0.9, green: 0.15, blue: 0.23)
    private var countries: [String] { ["All"] + Array(Set(rows.flatMap(\.countries))).sorted() }
    private var filtered: [CatalogTitle] { rows.filter { row in
        (type == "All" || row.type == type) && (country == "All" || row.countries.contains(country)) && row.releaseYear >= minimumYear && (search.isEmpty || row.title.localizedCaseInsensitiveContains(search) || row.genres.localizedCaseInsensitiveContains(search))
    } }
    private var years: [CatalogGroup] { CatalogAnalytics.groups(filtered) { [String($0.releaseYear)] }.sorted { $0.name < $1.name } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("THE STORY BEHIND THE CATALOG").font(.caption.bold()).tracking(2).foregroundStyle(red)
                    Text("StreamLens").font(.system(size: 40, weight: .bold, design: .rounded))
                    Text("Explore what gets made.\nFind the patterns.").font(.title3).foregroundStyle(.secondary)
                    Label(source, systemImage: "externaldrive").font(.caption).foregroundStyle(.secondary)
                    HStack { Button { importing = true } label: { Label("Import CSV", systemImage: "square.and.arrow.down") }.buttonStyle(.borderedProminent); Button("Sample") { loadSample() }.buttonStyle(.bordered) }
                    if let error { Text(error).foregroundStyle(.red).font(.callout) }
                    TextField("Search titles or genres", text: $search).textFieldStyle(.roundedBorder)
                    Picker("Content type", selection: $type) { Text("All").tag("All"); Text("Movies").tag("Movie"); Text("TV shows").tag("TV Show") }.pickerStyle(.segmented)
                    HStack {
                        Picker("Country", selection: $country) { ForEach(countries, id: \.self) { Text($0).tag($0) } }.pickerStyle(.menu)
                        Spacer()
                        Picker("Released", selection: $minimumYear) { Text("All years").tag(0); Text("2010+").tag(2010); Text("2020+").tag(2020) }.pickerStyle(.menu)
                    }
                    HStack { metric("TITLES", filtered.count); Spacer(); metric("MOVIES", filtered.filter { $0.type == "Movie" }.count); Spacer(); metric("COUNTRIES", Set(filtered.flatMap(\.countries)).count) }
                    if filtered.isEmpty { ContentUnavailableView.search(text: search) }
                    else {
                        card("Release timeline", caption: "Titles by original release year") {
                            Chart(years) { item in BarMark(x: .value("Year", item.name), y: .value("Titles", item.count)).foregroundStyle(red.gradient).cornerRadius(3) }.frame(height: 200)
                        }
                        card("Genres in focus", caption: "A title may belong to more than one genre") {
                            Chart(Array(CatalogAnalytics.groups(filtered, values: { $0.genreList }).prefix(6))) { item in BarMark(x: .value("Titles", item.count), y: .value("Genre", item.name)).foregroundStyle(red.opacity(0.8)) }.frame(height: 210)
                        }
                        card("Content ratings", caption: "Counts in your current selection") {
                            Chart(CatalogAnalytics.groups(filtered, values: { [$0.rating.isEmpty ? "Unknown" : $0.rating] })) { item in SectorMark(angle: .value("Titles", item.count), innerRadius: .ratio(0.65)).foregroundStyle(by: .value("Rating", item.name)) }.frame(height: 220)
                        }
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Explore titles").font(.title3.bold())
                            ForEach(Array(filtered.prefix(50))) { title in
                                HStack { RoundedRectangle(cornerRadius: 8).fill(red.opacity(0.15)).frame(width: 42, height: 50).overlay(Image(systemName: title.type == "Movie" ? "film" : "tv").foregroundStyle(red)); VStack(alignment: .leading, spacing: 4) { Text(title.title).font(.subheadline.bold()); Text("\(title.releaseYear) · \(title.type) · \(title.rating)").font(.caption).foregroundStyle(.secondary) }; Spacer() }
                            }
                            if filtered.count > 50 { Text("Showing the first 50 of \(filtered.count) filtered titles.").font(.caption).foregroundStyle(.secondary) }
                        }.padding(18).background(.background, in: RoundedRectangle(cornerRadius: 20))
                    }
                    Text("Independent portfolio project. Catalog metadata cannot tell us views, watch time, or Netflix engagement. Imported files stay on this device. Invalid CSV rows are skipped.").font(.footnote).foregroundStyle(.secondary)
                }.padding(22)
            }.background(Color(uiColor: .systemGroupedBackground)).navigationTitle("Catalog insights").navigationBarTitleDisplayMode(.inline)
                .task { if rows.isEmpty { loadSample() } }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.commaSeparatedText], allowsMultipleSelection: false) { result in
                    Task { await importFile(result) }
                }
        }.tint(red)
    }
    private func metric(_ name: String, _ count: Int) -> some View { VStack(alignment: .leading, spacing: 7) { Text(count.formatted()).font(.system(size: 28, weight: .bold, design: .rounded)); Text(name).font(.caption2.bold()).foregroundStyle(.secondary) } }
    private func card<Content: View>(_ title: String, caption: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) { Text(title).font(.title3.bold()); Text(caption).font(.caption).foregroundStyle(.secondary); content() }.padding(18).background(.background, in: RoundedRectangle(cornerRadius: 20))
    }
    private func loadSample() {
        do { guard let url = Bundle.main.url(forResource: "sample", withExtension: "json") else { throw CatalogError.invalid("Sample resource is missing.") }; rows = try JSONDecoder().decode([CatalogTitle].self, from: Data(contentsOf: url)); source = "Illustrative sample · not Netflix's full catalog"; reset() } catch { self.error = error.localizedDescription }
    }
    private func reset() { type = "All"; country = "All"; minimumYear = 0; search = ""; error = nil }
    @MainActor private func importFile(_ result: Result<[URL], Error>) async {
        do {
            guard let url = try result.get().first else { return }
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let imported = try await Task.detached(priority: .userInitiated) {
                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size <= 20_000_000 else { throw CatalogError.invalid("Choose a CSV smaller than 20 MB.") }
                return try CSVReader.catalog(String(contentsOf: url, encoding: .utf8))
            }.value
            rows = imported; source = "Imported: \(url.lastPathComponent) · \(rows.count) valid titles"; reset()
        } catch { self.error = error.localizedDescription }
    }
}
