import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    @State private var tab = 0
    @State private var showAdd = false

    var body: some View {
        let p = Palette(scheme: scheme)
        let tabs = ["Настройки", "О программе", "Об авторе"]

        NavigationStack {
            ZStack {
                (scheme == .dark ? Color(white: 0.04) : Color(white: 0.965))
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        SegmentedTabs(items: tabs, index: $tab, palette: p)

                        switch tab {
                        case 0: settingsPane(p)
                        case 1: aboutPane(p)
                        default: authorPane(p)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundColor(p.text)
                }
            }
            .sheet(isPresented: $showAdd) {
                AddSubscriptionView().environmentObject(store)
            }
        }
    }

    // MARK: - Настройки

    private func settingsPane(_ p: Palette) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Интерфейс", palette: p)
                HStack(spacing: 6) {
                    ForEach(ThemeMode.allCases) { mode in
                        Button {
                            store.theme = mode
                            store.persistTheme()
                        } label: {
                            Text(mode.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(store.theme == mode ? p.buttonFg : p.dim)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(store.theme == mode ? p.buttonBg : p.surface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                                .stroke(store.theme == mode ? Color.clear : p.line, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(14)
            .card(p)

            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Подписки", palette: p)
                ForEach(store.subscriptions) { sub in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(sub.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(p.text.opacity(0.92))
                                .lineLimit(1)
                            Text("\(sub.servers.count) серверов · \(dateText(sub.updatedAt))")
                                .font(.system(size: 9.5))
                                .foregroundColor(p.dim2)
                        }
                        Spacer(minLength: 6)
                        if !sub.url.isEmpty {
                            Button {
                                Task { await store.refresh(sub) }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(p.dim)
                            }
                            .buttonStyle(.plain)
                        }
                        Button {
                            store.remove(sub)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(p.dim2)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 6)
                    Divider().overlay(p.line)
                }

                Button {
                    showAdd = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Добавить подписку")
                            .font(.system(size: 11.5, weight: .medium))
                    }
                    .foregroundColor(p.text.opacity(0.9))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                Text("Автообновление подписки")
                    .font(.system(size: 11))
                    .foregroundColor(p.dim)
                    .padding(.top, 8)

                HStack {
                    Menu {
                        ForEach([0, 1, 3, 6, 12, 24], id: \.self) { value in
                            Button(value == 0 ? "Отключено" : "\(value) ч") {
                                store.updateInterval = value
                                store.persistInterval()
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(store.updateInterval == 0 ? "Отключено" : "\(store.updateInterval) ч")
                                .font(.system(size: 11.5))
                                .foregroundColor(p.text.opacity(0.9))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(p.dim2)
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(p.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(p.line, lineWidth: 1)
                                )
                        )
                    }
                    Spacer()
                }
            }
            .padding(14)
            .card(p)

            Text("IPv4, без телеметрии. Ключи и UUID не покидают устройство.")
                .font(.system(size: 9.5))
                .foregroundColor(p.dim2)
                .padding(.horizontal, 4)
        }
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - О программе

    private func aboutPane(_ p: Palette) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("XOLIRX VPN")
                    .font(.system(size: 21, weight: .regular, design: .serif))
                    .foregroundColor(p.text)
                Text("Версия 2.1.1 · iOS")
                    .font(.system(size: 10))
                    .tracking(0.8)
                    .foregroundColor(p.dim)
                Text("Менеджер подписок и конфигов в монохромной эстетике. Туннель поднимает выбранный VPN-клиент.")
                    .font(.system(size: 11))
                    .foregroundColor(p.dim)
                    .lineSpacing(3)
                    .padding(.top, 4)
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Что внутри", palette: p)
                kv("Подписки", "base64, ссылки и ключи", p)
                Divider().overlay(p.line)
                kv("Протоколы", "VLESS, VMess, Trojan, SS, Hysteria2", p)
                Divider().overlay(p.line)
                kv("Пинг", "реальный TCP-хендшейк", p)
                Divider().overlay(p.line)
                kv("Конфиг", "экспорт sing-box JSON", p)
                Divider().overlay(p.line)
                kv("Сеть", "только IPv4", p)
            }
            .padding(14)
            .card(p)

            Text("Флаги стран обесцвечены, фон — чёрно-белая фотография: палитра остаётся строгой.")
                .font(.system(size: 9.5))
                .foregroundColor(p.dim2)
                .padding(.horizontal, 4)
        }
    }

    private func kv(_ key: String, _ value: String, _ p: Palette) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(key)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(p.text.opacity(0.9))
                .frame(width: 92, alignment: .leading)
            Text(value)
                .font(.system(size: 11))
                .foregroundColor(p.dim)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Об авторе

    private func authorPane(_ p: Palette) -> some View {
        VStack(spacing: 14) {
            if let image = UIImage(named: "avatar") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 74, height: 74)
                    .saturation(0)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(p.lineStrong, lineWidth: 1))
            }

            VStack(spacing: 4) {
                Text("xolirx")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(p.text)
                Text("РАЗРАБОТЧИК")
                    .font(.system(size: 8.5, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(p.dim2)
            }

            Text("Автор XOLIRX VPN. Делаю небольшой честный клиент без рекламы, телеметрии и «красивых» цифр: только реальные подключения и понятные настройки.")
                .font(.system(size: 11))
                .foregroundColor(p.dim)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 6)

            Link(destination: URL(string: "https://t.me/xolirx")!) {
                HStack(spacing: 6) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 11))
                    Text("Telegram · @xolirx")
                        .font(.system(size: 11.5, weight: .medium))
                }
                .foregroundColor(p.text.opacity(0.9))
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(p.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(p.line, lineWidth: 1)
                        )
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Связь", palette: p)
                kv("Telegram", "@xolirx", p)
                Divider().overlay(p.line)
                kv("Проект", "XOLIRX VPN 2.1.1", p)
                Divider().overlay(p.line)
                kv("Платформа", "iPhone · iOS 16+", p)
            }
            .padding(14)
            .card(p)
            .padding(.top, 4)

            Text("Если приложение помогло — просто пользуйтесь. Обратная связь и отчёты об ошибках приветствуются в Telegram.")
                .font(.system(size: 9.5))
                .foregroundColor(p.dim2)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}
