import Foundation

/// Сборка sing-box-конфига для выбранного узла. Пригодится, если пользователь
/// предпочитает готовый клиент: конфиг копируется и импортируется в sing-box.
enum ConfigBuilder {

    static func json(for server: VpnServer) -> String? {
        guard let outbound = outbound(for: server) else { return nil }
        let config: [String: Any] = [
            "log": ["level": "warn"],
            "inbounds": [],
            "outbounds": [
                outbound,
                ["type": "direct", "tag": "direct"],
                ["type": "block", "tag": "block"]
            ],
            "route": ["final": "proxy"]
        ]
        guard let data = try? JSONSerialization.data(
            withJSONObject: config,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        ) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func outbound(for server: VpnServer) -> [String: Any]? {
        guard let parts = LinkParts(link: server.link) else { return nil }
        switch server.proto {
        case "vless": return vless(parts)
        case "trojan": return trojan(parts)
        case "ss": return shadowsocks(server.link, parts)
        case "hysteria2": return hysteria2(parts)
        case "vmess": return vmess(server.link)
        default: return nil
        }
    }

    // MARK: - vless

    private static func vless(_ p: LinkParts) -> [String: Any]? {
        // XHTTP — транспорт Xray; sing-box его не умеет, не выдаём битый конфиг.
        if (p.query["type"] ?? "tcp") == "xhttp" { return nil }
        var o: [String: Any] = [
            "type": "vless",
            "tag": "proxy",
            "server": p.host,
            "server_port": p.port,
            "uuid": p.userinfo
        ]
        if let flow = p.query["flow"], !flow.isEmpty { o["flow"] = flow }
        if let tls = tlsSettings(p, reality: p.query["security"] == "reality") { o["tls"] = tls }
        if let transport = transportSettings(p) { o["transport"] = transport }
        return o
    }

    // MARK: - trojan

    private static func trojan(_ p: LinkParts) -> [String: Any] {
        var o: [String: Any] = [
            "type": "trojan",
            "tag": "proxy",
            "server": p.host,
            "server_port": p.port,
            "password": p.userinfo
        ]
        o["tls"] = tlsSettings(p, reality: false) ?? ["enabled": true, "server_name": p.host]
        if let transport = transportSettings(p) { o["transport"] = transport }
        return o
    }

    // MARK: - shadowsocks

    private static func shadowsocks(_ link: String, _ p: LinkParts) -> [String: Any]? {
        var rest = String(link.dropFirst("ss://".count))
        if let hash = rest.firstIndex(of: "#") { rest = String(rest[..<hash]) }
        if let q = rest.firstIndex(of: "?") { rest = String(rest[..<q]) }

        var credentials = ""
        if let at = rest.lastIndex(of: "@") {
            let info = String(rest[..<at])
            credentials = SubscriptionParser.decodeBase64(info) ?? info
        } else if let decoded = SubscriptionParser.decodeBase64(rest),
                  let at = decoded.lastIndex(of: "@") {
            credentials = String(decoded[..<at])
        }
        guard let colon = credentials.firstIndex(of: ":") else { return nil }
        let method = String(credentials[..<colon])
        let password = String(credentials[credentials.index(after: colon)...])
        return [
            "type": "shadowsocks",
            "tag": "proxy",
            "server": p.host,
            "server_port": p.port,
            "method": method,
            "password": password
        ]
    }

    // MARK: - hysteria2

    private static func hysteria2(_ p: LinkParts) -> [String: Any] {
        var o: [String: Any] = [
            "type": "hysteria2",
            "tag": "proxy",
            "server": p.host,
            "server_port": p.port,
            "password": p.userinfo
        ]
        var tls: [String: Any] = ["enabled": true]
        tls["server_name"] = p.query["sni"] ?? p.query["peer"] ?? p.host
        // pinSHA256 sing-box-клиент не проверяет: как и в десктопной версии,
        // откатываемся на TLS без пининга, иначе узел просто не подключится.
        if p.query["insecure"] == "1" || p.query["pinSHA256"] != nil {
            tls["insecure"] = true
        }
        o["tls"] = tls
        if let obfs = p.query["obfs"], !obfs.isEmpty {
            o["obfs"] = ["type": obfs, "password": p.query["obfs-password"] ?? ""]
        }
        return o
    }

    // MARK: - vmess

    private static func vmess(_ link: String) -> [String: Any]? {
        let raw = String(link.dropFirst("vmess://".count))
        guard let decoded = SubscriptionParser.decodeBase64(raw),
              let data = decoded.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let obj = json as? [String: Any] else { return nil }
        let host = SubscriptionParser.stringValue(obj["add"])
        let port = SubscriptionParser.intValue(obj["port"])
        let uuid = SubscriptionParser.stringValue(obj["id"])
        guard !host.isEmpty, port > 0, !uuid.isEmpty else { return nil }

        var o: [String: Any] = [
            "type": "vmess",
            "tag": "proxy",
            "server": host,
            "server_port": port,
            "uuid": uuid,
            "security": SubscriptionParser.stringValue(obj["scy"]).isEmpty
                ? "auto"
                : SubscriptionParser.stringValue(obj["scy"]),
            "alter_id": SubscriptionParser.intValue(obj["aid"])
        ]
        if SubscriptionParser.stringValue(obj["tls"]) == "tls" {
            let sni = SubscriptionParser.stringValue(obj["sni"])
            let headerHost = SubscriptionParser.stringValue(obj["host"])
            o["tls"] = [
                "enabled": true,
                "server_name": sni.isEmpty ? (headerHost.isEmpty ? host : headerHost) : sni
            ]
        }
        let net = SubscriptionParser.stringValue(obj["net"])
        let path = SubscriptionParser.stringValue(obj["path"])
        let headerHost = SubscriptionParser.stringValue(obj["host"])
        if net == "ws" {
            o["transport"] = [
                "type": "ws",
                "path": path.isEmpty ? "/" : path,
                "headers": ["Host": headerHost.isEmpty ? host : headerHost]
            ]
        } else if net == "grpc" {
            o["transport"] = ["type": "grpc", "service_name": path]
        } else if net == "h2" || net == "http" {
            o["transport"] = [
                "type": "http",
                "host": [headerHost.isEmpty ? host : headerHost],
                "path": path.isEmpty ? "/" : path
            ]
        }
        return o
    }

    // MARK: - helpers

    private static func tlsSettings(_ p: LinkParts, reality: Bool) -> [String: Any]? {
        let security = p.query["security"] ?? ""
        guard security == "tls" || security == "reality" || reality else { return nil }
        var tls: [String: Any] = ["enabled": true]
        tls["server_name"] = p.query["sni"] ?? p.query["host"] ?? p.host
        if let alpn = p.query["alpn"], !alpn.isEmpty {
            tls["alpn"] = alpn.split(separator: ",").map(String.init)
        }
        if let fp = p.query["fp"], !fp.isEmpty {
            tls["utls"] = ["enabled": true, "fingerprint": fp]
        }
        if reality {
            tls["reality"] = [
                "enabled": true,
                "public_key": p.query["pbk"] ?? "",
                "short_id": p.query["sid"] ?? ""
            ]
        }
        return tls
    }

    private static func transportSettings(_ p: LinkParts) -> [String: Any]? {
        switch p.query["type"] ?? "tcp" {
        case "ws":
            return ["type": "ws", "path": p.query["path"] ?? "/", "headers": ["Host": p.query["host"] ?? p.host]]
        case "grpc":
            return ["type": "grpc", "service_name": p.query["serviceName"] ?? ""]
        case "http", "h2":
            return ["type": "http", "host": [p.query["host"] ?? p.host], "path": p.query["path"] ?? "/"]
        default:
            return nil
        }
    }
}
