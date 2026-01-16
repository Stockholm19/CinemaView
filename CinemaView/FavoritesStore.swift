import Foundation

struct FavoriteItem: Identifiable, Codable, Equatable {
    var id = UUID()
    let title: String
    let url: URL
}

class FavoritesStore: ObservableObject {
    @Published var items: [FavoriteItem] = [] {
        didSet {
            save()
        }
    }
    
    private let saveKey = "CinemaView_Favorites"
    
    init() {
        load()
    }
    
    func add(title: String, url: URL) {
        if !items.contains(where: { $0.url == url }) {
            items.append(FavoriteItem(title: title, url: url))
        }
    }
    
    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    func toggle(title: String, url: URL) {
        if let index = items.firstIndex(where: { $0.url == url }) {
            items.remove(at: index)
        } else {
            add(title: title, url: url)
        }
    }
    
    func isFavorite(url: URL?) -> Bool {
        guard let url = url else { return false }
        return items.contains(where: { $0.url == url })
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data) {
            self.items = decoded
        }
    }
}
