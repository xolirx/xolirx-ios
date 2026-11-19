import Foundation

/// Разбор подписки: base64-список и отдельные ключи vless / vmess / trojan /
/// shadowsocks / hysteria2.
enum SubscriptionParser {

    static func parse(text: String, subscriptionID: UUID) -> [VpnServer] {
        var body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return [] }
        if !body.contains("://"), let decoded = decodeBase64(body) {
            body = decoded
        }
        var out: [VpnServer] = []
        var seen = Set<String>()
        for raw in body.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, line.contains("://") else { continue }
            guard let server = parseLink(line, subscriptionID: subscriptionID) else { continue }
            if seen.insert(server.link).inserted { out.append(server) }
        }
        return out
    }

    /// Убирает пробелы вокруг названия: subscription часто отдаёт
    /// «🇸🇪 Sweden  » с хвостовыми пробелами.
    static func cleanTitle(_ raw: String, fallback: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    /// Значение из JSON-словаря vmess: строка или число.
    static func stringValue(_ any: Any?) -> String {
        if let value = any as? String { return value }
        if let value = any as? NSNumber { return value.stringValue }
        return ""
    }

    static func intValue(_ any: Any?) -> Int {
        if let value = any as? NSNumber { return value.intValue }
        if let value = any as? String { return Int(value) ?? 0 }
        return 0
    }

    static func decodeBase64(_ s: String) -> String? {
        var t = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        t = String(t.filter { !$0.isWhitespace })
        while t.count % 4 != 0 { t += "=" }
        guard let data = Data(base64Encoded: t, options: .ignoreUnknownCharacters) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func parseLink(_ link: String, subscriptionID: UUID) -> VpnServer? {
        guard let range = link.range(of: "://") else { return nil }
        let scheme = link[..<range.lowerBound].lowercased()
        switch scheme {
        case "vless", "trojan", "hysteria2", "hy2":
            return parseStandard(link, proto: scheme == "hy2" ? "hysteria2" : scheme, subscriptionID: subscriptionID)
        case "ss":
            return parseShadowsocks(link, subscriptionID: subscriptionID)
        case "vmess":
            return parseVMess(link, subscriptionID: subscriptionID)
        default:
            return nil
        }
    }

    // MARK: - vless / trojan / hysteria2

    private static func parseStandard(_ link: String, proto: String, subscriptionID: UUID) -> VpnServer? {
        guard let parts = LinkParts(link: link) else { return nil }
        let name = cleanTitle(parts.name, fallback: parts.host)
        let country = CountryCatalog.code(for: name + " " + parts.host)
        return VpnServer(
            title: name,
            countryCode: country,
            host: parts.host,
            port: parts.port,
            proto: proto,
            link: link,
            subscriptionID: subscriptionID
        )
    }

    // MARK: - shadowsocks

    private static func parseShadowsocks(_ link: String, subscriptionID: UUID) -> VpnServer? {
        var rest = String(link.dropFirst("ss://".count))
        var name = ""
        if let hash = rest.firstIndex(of: "#") {
            name = String(rest[rest.index(after: hash)...]).removingPercentEncoding ?? ""
            rest = String(rest[..<hash])
        }
        if let q = rest.firstIndex(of: "?") { rest = String(rest[..<q]) }

        var credentials = ""
        var hostPort = ""
        if let at = rest.lastIndex(of: "@") {
            let userinfo = String(rest[..<at])
            credentials = decodeBase64(userinfo) ?? userinfo.removingPercentEncoding ?? userinfo
            hostPort = String(rest[rest.index(after: at)...])
        } else if let decoded = decodeBase64(rest) {
            guard let at = decoded.lastIndex(of: "@") else { return nil }
            credentials = String(decoded[..<at])
            hostPort = String(decoded[decoded.index(after: at)...])
        } else {
            return nil
        }

        guard credentials.contains(":"), let split = LinkParts.hostPort(hostPort) else { return nil }
        let title = cleanTitle(name, fallback: split.host)
        return VpnServer(
            title: title,
            countryCode: CountryCatalog.code(for: title + " " + split.host),
            host: split.host,
            port: split.port,
            proto: "ss",
            link: link,
            subscriptionID: subscriptionID
        )
    }

    // MARK: - vmess

    private static func parseVMess(_ link: String, subscriptionID: UUID) -> VpnServer? {
        let raw = String(link.dropFirst("vmess://".count))
        guard let decoded = decodeBase64(raw),
              let data = decoded.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let obj = json as? [String: Any] else { return nil }
        let host = stringValue(obj["add"])
        let port = intValue(obj["port"])
        guard !host.isEmpty, port > 0 else { return nil }
        let ps = stringValue(obj["ps"])
        let title = cleanTitle(ps, fallback: host)
        return VpnServer(
            title: title,
            countryCode: CountryCatalog.code(for: title + " " + host),
            host: host,
            port: port,
            proto: "vmess",
            link: link,
            subscriptionID: subscriptionID
        )
    }
}

/// Общий разбор ссылки: схема, userinfo, host, port, query, fragment.
struct LinkParts {
    var scheme = ""
    var userinfo = ""
    var host = ""
    var port = 443
    var query: [String: String] = [:]
    var name = ""

    init?(link: String) {
        guard let range = link.range(of: "://") else { return nil }
        scheme = String(link[..<range.lowerBound]).lowercased()
        var rest = String(link[range.upperBound...])

        if let hash = rest.firstIndex(of: "#") {
            name = String(rest[rest.index(after: hash)...]).removingPercentEncoding ?? ""
            rest = String(rest[..<hash])
        }
        if let q = rest.firstIndex(of: "?") {
            let qs = String(rest[rest.index(after: q)...])
            rest = String(rest[..<q])
            for pair in qs.split(separator: "&") {
                let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                let key = String(kv[0]).removingPercentEncoding ?? String(kv[0])
                let value = kv.count > 1 ? (String(kv[1]).removingPercentEncoding ?? String(kv[1])) : ""
                query[key] = value
            }
        }
        guard let at = rest.lastIndex(of: "@") else { return nil }
        userinfo = String(rest[..<at]).removingPercentEncoding ?? String(rest[..<at])
        guard let split = LinkParts.hostPort(String(rest[rest.index(after: at)...])) else { return nil }
        host = split.host
        port = split.port
    }

    static func hostPort(_ raw: String) -> (host: String, port: Int)? {
        var s = raw
        // hysteria2-ссылки приходят как host:port/?sni=… — хвостовой слэш
        // ломает Int(port), поэтому убираем его до разбора.
        while s.hasSuffix("/") { s.removeLast() }
        if s.hasPrefix("["), let close = s.firstIndex(of: "]") {
            let host = String(s[s.index(after: s.startIndex)..<close])
            let after = s.index(after: close)
            var port = 443
            if after < s.endIndex, s[after] == ":" {
                port = Int(s[s.index(after: after)...]) ?? 443
            }
            return (host, port)
        }
        guard let colon = s.lastIndex(of: ":") else { return nil }
        let host = String(s[..<colon])
        guard let port = Int(s[s.index(after: colon)...]), port > 0 else { return nil }
        return (host, port)
    }
}
