import Foundation

enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case system
    case dark
    case light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Системная"
        case .dark: return "Тёмная"
        case .light: return "Светлая"
        }
    }
}

struct VpnServer: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var countryCode: String
    var host: String
    var port: Int
    var proto: String
    var link: String
    var subscriptionID: UUID?

    var flag: String {
        let code = countryCode.uppercased()
        guard code.count == 2 else { return "🌐" }
        var scalars: [UnicodeScalar] = []
        for u in code.unicodeScalars {
            guard let scalar = UnicodeScalar(127397 + u.value) else { return "🌐" }
            scalars.append(scalar)
        }
        return String(scalars.map { Character($0) })
    }

    var endpoint: String { "\(host):\(port)" }
}

struct Subscription: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var url: String
    var servers: [VpnServer]
    var updatedAt: Date
}
