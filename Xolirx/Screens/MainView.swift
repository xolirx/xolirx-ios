import SwiftUI

struct MainView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme

    @State private var sheet: Sheet?

    private enum Sheet: String, Identifiable {
        case servers, settings, add
        var id: String { rawValue }
    }

    var body: some View {
        let p = Palette(scheme: scheme)

        ZStack {
            ArtBackground(scheme: scheme)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header(p)
                    hero(p)
                    connectCard(p)
                    footer(p)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 36)
            }
        }
        .overlay(alignment: .bottom) { toast(p) }
        .sheet(item: $sheet) { item in
            Group {
                switch item {
                case .servers: ServersSheet()
                case .settings: SettingsView()
                case .add: AddSubscriptionView()
                }
            }
            .environmentObject(store)
        }
        .task {
            if store.servers.isEmpty { sheet = .add }
            await store.refreshStale()
        }
    }

    // MARK: - Шапка

    private func header(_ p: Palette) -> some View {
        HStack(alignment: .center, spacing: 10) {
            HStack(spacing: 6) {
                Text("XOLIRX")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(3.2)
                    .foregroundColor(p.text)
                Rectangle()
                    .fill(p.lineStrong)
                    .frame(width: 14, height: 1)
                Text("VPN")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(2.4)
                    .foregroundColor(p.dim)
            }
            Spacer()
            Text("v2.1")
                .font(.system(size: 9, weight: .medium))
                .tracking(1.2)
                .foregroundColor(p.dim)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(
                    Capsule().stroke(p.line, lineWidth: 1)
                )
            Button {
                sheet = .settings
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(p.dim)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    // MARK: - Заголовок

    private func hero(_ p: Palette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Rectangle().fill(p.line).frame(width: 26, height: 1)
                Text("ЗАЩИЩЁННЫЙ КАНАЛ")
                    .font(.system(size: 8.5, weight: .semibold))
                    .tracking(2.2)
                    .foregroundColor(p.dim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
                Rectangle().fill(p.line).frame(width: 26, height: 1)
            }

            (Text("тихий ")
                .font(.system(size: 40, weight: .regular, design: .serif))
             + Text("туннель")
                .font(.system(size: 40, weight: .regular, design: .serif))
                .italic())
                .foregroundColor(p.text)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            HStack(spacing: 7) {
                Circle()
                    .fill(p.text.opacity(0.85))
                    .frame(width: 4, height: 4)
                Text(statusLine)
                    .font(.system(size: 11.5))
                    .tracking(0.3)
                    .foregroundColor(p.dim)
            }
        }
        .padding(.top, 14)
    }

    private var statusLine: String {
        if store.servers.isEmpty { return "добавьте подписку" }
        if let server = store.selectedServer {
            return "готово · \(server.title)"
        }
        return "готово · серверов \(store.servers.count)"
    }

    // MARK: - Карточка подключения

    private func connectCard(_ p: Palette) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Подключение", palette: p)

            Button(action: primaryAction) {
                Text(primaryTitle)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(p.buttonFg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(p.buttonBg)
                    )
            }
            .buttonStyle(.plain)

            Button {
                sheet = .servers
            } label: {
                HStack(spacing: 11) {
                    Text(store.selectedServer?.flag ?? "🌐")
                        .font(.system(size: 17))
                        .saturation(0)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.selectedServer?.title ?? "Сервер не выбран")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(p.text.opacity(0.92))
                            .lineLimit(1)
                        Text(store.selectedServer?.endpoint ?? "нажмите, чтобы выбрать")
                            .font(.system(size: 9.5))
                            .foregroundColor(p.dim2)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 6)
                    if let server = store.selectedServer {
                        Text(store.pingText(for: server.id))
                            .font(.system(size: 10.5))
                            .monospacedDigit()
                            .foregroundColor(p.text)
                            .opacity(store.pingOpacity(for: server.id))
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(p.dim2)
                }
                .padding(.horizontal, 12)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(p.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(p.line, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                MonoActionButton(
                    title: store.pingBusy ? "Проверка…" : "Проверить",
                    icon: "waveform.path.ecg",
                    palette: p
                ) {
                    guard !store.pingBusy else { return }
                    Task { await store.pingAll() }
                }
                MonoActionButton(title: "Конфиг", icon: "doc.on.doc", palette: p) {
                    store.copyConfig()
                }
            }

            Text("Пинг — реальный TCP-хендшейк до узла. Подписка и выбор сервера хранятся на устройстве.")
                .font(.system(size: 9.5))
                .foregroundColor(p.dim2)
                .lineSpacing(2)
        }
        .padding(16)
        .card(p)
    }

    private var primaryTitle: String {
        if store.servers.isEmpty { return "Добавить подписку" }
        if store.selectedServer == nil { return "Выбрать сервер" }
        return "Открыть в VPN-клиенте"
    }

    private func primaryAction() {
        if store.servers.isEmpty {
            sheet = .add
        } else if store.selectedServer == nil {
            sheet = .servers
        } else {
            store.openInClientOrCopy()
        }
    }

    private func footer(_ p: Palette) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("XOLIRX VPN 2.1 · iOS")
                .font(.system(size: 9.5))
                .tracking(1.1)
                .foregroundColor(p.dim2)
            Text("VPN-туннель поднимается в установленном клиенте (sing-box, Streisand, Shadowrocket). Приложение готовит подписку и конфиг.")
                .font(.system(size: 9.5))
                .foregroundColor(p.dim2)
                .lineSpacing(2)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Тост

    @ViewBuilder
    private func toast(_ p: Palette) -> some View {
        if let text = store.toast {
            Text(text)
                .font(.system(size: 11.5))
                .foregroundColor(p.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(p.card)
                        .overlay(Capsule().stroke(p.line, lineWidth: 1))
                )
                .padding(.bottom, 20)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeOut(duration: 0.2), value: store.toast)
        }
    }
}
