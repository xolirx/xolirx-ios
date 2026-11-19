import Combine
import Foundation
import UIKit

enum StoreError: LocalizedError {
    case badURL
    case http(Int)
    case empty
    case parse

    var errorDescription: String? {
        switch self {
        case .badURL: return "Некорректная ссылка"
        case .http(let code): return "Сервер подписки ответил \(code)"
        case .empty: return "В ответе нет серверов"
        case .parse: return "Не удалось разобрать подписку"
        }
    }
}

@MainActor
final class AppStore: ObservableObject {

    @Published var subscriptions: [Subscription] = []
    @Published var selectedID: UUID?
    @Published var ping: [UUID: Int] = [:]      // -1 — нет ответа
    @Published var pingBusy = false
    @Published var theme: ThemeMode = .dark
    @Published var updateInterval = 12          // часы; 0 — выключено
    @Published var toast: String?
    @Published var addBusy = false
    @Published var addError: String?
    @Published var clientHelp = false
    @Published var helpText = ""

    private let defaults = UserDefaults.standard
    private let subsKey = "xolirx.subs.v2"
    private let selectedKey = "xolirx.selected.v2"
    private let themeKey = "xolirx.theme.v2"
    private let intervalKey = "xolirx.interval.v2"
    private var toastTask: Task<Void, Never>?

    init() {
        load()
    }

    // MARK: - Производные значения

    var servers: [VpnServer] {
        subscriptions.flatMap { $0.servers }
    }

    var selectedServer: VpnServer? {
        guard let id = selectedID else { return nil }
        return servers.first { $0.id == id }
    }

    var activeSubscription: Subscription? {
        guard let server = selectedServer else { return subscriptions.first }
        return subscriptions.first { $0.id == server.subscriptionID } ?? subscriptions.first
    }

    func pingText(for id: UUID) -> String {
        if let value = ping[id] {
            return value < 0 ? "нет ответа" : "\(value) мс"
        }
        return pingBusy ? "…" : "—"
    }

    func pingOpacity(for id: UUID) -> Double {
        guard let value = ping[id] else { return 0.45 }
        if value < 0 { return 0.4 }
        if value <= 150 { return 1 }
        if value <= 350 { return 0.8 }
        return 0.6
    }

    // MARK: - Загрузка и сохранение

    private func load() {
        if let data = defaults.data(forKey: subsKey),
           let list = try? JSONDecoder().decode([Subscription].self, from: data) {
            subscriptions = list
        }
        if let raw = defaults.string(forKey: themeKey), let value = ThemeMode(rawValue: raw) {
            theme = value
        }
        updateInterval = defaults.object(forKey: intervalKey) as? Int ?? 12
        if let raw = defaults.string(forKey: selectedKey) {
            selectedID = UUID(uuidString: raw)
        }
        if selectedID == nil || !servers.contains(where: { $0.id == selectedID }) {
            selectedID = servers.first?.id
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(subscriptions) {
            defaults.set(data, forKey: subsKey)
        }
        defaults.set(theme.rawValue, forKey: themeKey)
        defaults.set(updateInterval, forKey: intervalKey)
        defaults.set(selectedID?.uuidString, forKey: selectedKey)
    }

    func persistTheme() { save() }
    func persistInterval() { save() }

    // MARK: - Добавление

    func addInput(_ text: String, name: String?) async {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            addError = "Вставьте ссылку или ключ"
            return
        }
        // ATS в iOS не пропускает незашифрованный http: подсказываем сразу,
        // вместо непонятной сетевой ошибки.
        if raw.lowercased().hasPrefix("http://") {
            addError = "iOS блокирует http:// — используйте https://"
            return
        }
        addBusy = true
        addError = nil
        defer { addBusy = false }

        let lower = raw.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            do {
                try await loadRemote(urlString: raw, name: name)
            } catch {
                addError = error.localizedDescription
            }
        } else {
            let id = UUID()
            let list = SubscriptionParser.parse(text: raw, subscriptionID: id)
            guard !list.isEmpty else {
                addError = "В строке нет поддерживаемых ключей"
                return
            }
            let title = (name?.isEmpty == false ? name! : "Мои ключи")
            subscriptions.append(Subscription(id: id, name: title, url: "", servers: list, updatedAt: Date()))
            if selectedID == nil { selectedID = list.first?.id }
            save()
            showToast("Добавлено серверов: \(list.count)")
        }
    }

    private func loadRemote(urlString: String, name: String?) async throws {
        guard let url = URL(string: urlString) else { throw StoreError.badURL }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        // Подписка отдаёт формат по User-Agent. С v2rayN она присылает Xray JSON,
        // а с клиентским UA — обычный base64-список vless/hysteria2-ссылок.
        request.setValue("sing-box/1.11.0 (iOS)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw StoreError.http(http.statusCode)
        }
        guard let text = String(data: data, encoding: .utf8) else { throw StoreError.empty }

        let id = UUID()
        let list = SubscriptionParser.parse(text: text, subscriptionID: id)
        guard !list.isEmpty else { throw StoreError.empty }

        let fallback = URL(string: urlString)?.host ?? "Подписка"
        let title = (name?.isEmpty == false ? name! : fallback)
        let previousLink = selectedServer?.link
        if let index = subscriptions.firstIndex(where: { $0.url == urlString }) {
            subscriptions[index].servers = list
            subscriptions[index].updatedAt = Date()
            if name?.isEmpty == false { subscriptions[index].name = name! }
        } else {
            subscriptions.append(Subscription(id: id, name: title, url: urlString, servers: list, updatedAt: Date()))
        }

        // Обновление подписки не должно сбрасывать выбранный сервер на первый.
        if let link = previousLink, let same = servers.first(where: { $0.link == link }) {
            selectedID = same.id
        } else if selectedID == nil || !servers.contains(where: { $0.id == selectedID }) {
            selectedID = servers.first?.id
        }
        ping = [:]
        save()
        showToast("Загружено серверов: \(list.count)")
    }

    func refresh(_ subscription: Subscription) async {
        guard !subscription.url.isEmpty else { return }
        do {
            try await loadRemote(urlString: subscription.url, name: subscription.name)
        } catch {
            showToast(error.localizedDescription)
        }
    }

    func refreshStale(force: Bool = false) async {
        guard updateInterval > 0 || force else { return }
        let ttl = TimeInterval(updateInterval * 3600)
        for sub in subscriptions where !sub.url.isEmpty {
            if force || Date().timeIntervalSince(sub.updatedAt) > ttl {
                do {
                    try await loadRemote(urlString: sub.url, name: sub.name)
                } catch {
                    if force { showToast(error.localizedDescription) }
                }
            }
        }
    }

    func remove(_ subscription: Subscription) {
        subscriptions.removeAll { $0.id == subscription.id }
        if !servers.contains(where: { $0.id == selectedID }) {
            selectedID = servers.first?.id
        }
        save()
    }

    func select(_ server: VpnServer) {
        selectedID = server.id
        save()
    }

    // MARK: - Пинг

    func pingAll() async {
        guard !servers.isEmpty else { return }
        pingBusy = true
        ping = [:]
        let list = servers
        let limit = 4

        await withTaskGroup(of: (UUID, Int?).self) { group in
            var index = 0
            while index < min(limit, list.count) {
                let server = list[index]
                index += 1
                group.addTask {
                    (server.id, await TCPPing.measure(host: server.host, port: server.port))
                }
            }
            for await (id, value) in group {
                ping[id] = value ?? -1
                if index < list.count {
                    let server = list[index]
                    index += 1
                    group.addTask {
                        (server.id, await TCPPing.measure(host: server.host, port: server.port))
                    }
                }
            }
        }
        pingBusy = false
    }

    // MARK: - Клиенты и конфиг

    func copyConfig() {
        guard let server = selectedServer else {
            showToast("Сначала выберите сервер")
            return
        }
        guard let text = ConfigBuilder.json(for: server) else {
            UIPasteboard.general.string = server.link
            showToast("XHTTP не поддержан sing-box — скопирована ссылка")
            return
        }
        UIPasteboard.general.string = text
        showToast("Конфиг sing-box скопирован")
    }

    func copyShareLink() {
        guard let server = selectedServer else {
            showToast("Сначала выберите сервер")
            return
        }
        UIPasteboard.general.string = server.link
        showToast("Ссылка на сервер скопирована")
    }

    func openInClientOrCopy() {
        if let sub = activeSubscription, !sub.url.isEmpty {
            var allowed = CharacterSet.alphanumerics
            allowed.insert(charactersIn: "-._~")
            let encoded = sub.url.addingPercentEncoding(withAllowedCharacters: allowed) ?? sub.url
            let base64 = Data(sub.url.utf8).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
            let raw = [
                "sing-box://import-remote-profile?url=\(encoded)",
                "streisand://import/\(encoded)",
                "shadowrocket://add/sub://\(base64)",
                "sub://\(base64)"
            ]
            for item in raw {
                if let url = URL(string: item), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                    return
                }
            }
            UIPasteboard.general.string = sub.url
            helpText = "Ссылка на подписку уже в буфере обмена. Установите VPN-клиент и вставьте её при добавлении профиля."
            clientHelp = true
            return
        }

        UIPasteboard.general.string = selectedServer?.link ?? ""
        helpText = "Ссылка на сервер уже в буфере обмена. Установите VPN-клиент и вставьте её при добавлении узла."
        clientHelp = true
    }

    func copySubscriptionLink() {
        guard let sub = activeSubscription, !sub.url.isEmpty else {
            showToast("У этой подписки нет ссылки")
            return
        }
        UIPasteboard.general.string = sub.url
        showToast("Ссылка на подписку скопирована")
    }

    // MARK: - Тост

    private func showToast(_ text: String) {
        toast = text
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            if Task.isCancelled { return }
            self?.toast = nil
        }
    }
}
