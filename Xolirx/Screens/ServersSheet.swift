import SwiftUI

struct ServersSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    @State private var filter = ""

    var body: some View {
        let p = Palette(scheme: scheme)

        NavigationStack {
            ZStack {
                (scheme == .dark ? Color(white: 0.04) : Color(white: 0.965))
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        header(p)
                        if !countries.isEmpty {
                            chips(p)
                        }
                        ForEach(visible) { server in
                            row(server, p)
                        }
                        if visible.isEmpty {
                            Text("Серверов пока нет. Добавьте подписку в настройках.")
                                .font(.system(size: 12))
                                .foregroundColor(p.dim)
                                .padding(.top, 20)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Серверы")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundColor(p.text)
                }
            }
        }
    }

    private var visible: [VpnServer] {
        let list = store.servers
        guard !filter.isEmpty else {
            return list.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
        return list.filter { $0.countryCode == filter }
    }

    private var countries: [String] {
        var seen: [String] = []
        for server in store.servers where !server.countryCode.isEmpty {
            if !seen.contains(server.countryCode) { seen.append(server.countryCode) }
        }
        return seen
    }

    private func header(_ p: Palette) -> some View {
        HStack {
            Text("\(store.servers.count) серверов · \(store.subscriptions.count) подписок")
                .font(.system(size: 10.5))
                .foregroundColor(p.dim)
            Spacer()
            Button {
                guard !store.pingBusy else { return }
                Task { await store.pingAll() }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .semibold))
                    Text(store.pingBusy ? "проверка" : "пинг")
                        .font(.system(size: 10.5, weight: .medium))
                }
                .foregroundColor(p.text.opacity(0.85))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 10)
    }

    private func chips(_ p: Palette) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chip("Все", code: "", p: p)
                ForEach(countries, id: \.self) { code in
                    chip(code, code: code, p: p)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(_ title: String, code: String, p: Palette) -> some View {
        Button {
            filter = code
        } label: {
            Text(title)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(filter == code ? p.buttonFg : p.dim)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(filter == code ? p.buttonBg : p.surface)
                        .overlay(Capsule().stroke(filter == code ? Color.clear : p.line, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }

    private func row(_ server: VpnServer, _ p: Palette) -> some View {
        let selected = store.selectedID == server.id
        return Button {
            store.select(server)
            dismiss()
        } label: {
            HStack(spacing: 11) {
                Text(server.flag)
                    .font(.system(size: 17))
                    .saturation(0)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text(server.title)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(p.text.opacity(0.95))
                        .lineLimit(1)
                    Text("\(server.endpoint) · \(server.proto)")
                        .font(.system(size: 9.5))
                        .foregroundColor(p.dim2)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                Text(store.pingText(for: server.id))
                    .font(.system(size: 10.5))
                    .monospacedDigit()
                    .foregroundColor(p.text)
                    .opacity(store.pingOpacity(for: server.id))
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(p.text)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? p.surface : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(selected ? p.lineStrong : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
