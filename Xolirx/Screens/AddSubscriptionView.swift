import SwiftUI
import UIKit

struct AddSubscriptionView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var name = ""

    var body: some View {
        let p = Palette(scheme: scheme)

        NavigationStack {
            ZStack {
                (scheme == .dark ? Color(white: 0.04) : Color(white: 0.965))
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Ссылка или ключ")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(1.6)
                            .foregroundColor(p.dim)

                        TextEditor(text: $text)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(p.text)
                            .scrollContentBackground(.hidden)
                            .frame(height: 120)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(p.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(p.line, lineWidth: 1)
                                    )
                            )
                            .overlay(alignment: .topLeading) {
                                if text.isEmpty {
                                    Text("https://…  ·  vless://…  ·  hysteria2://…")
                                        .font(.system(size: 11.5))
                                        .foregroundColor(p.dim2)
                                        .padding(.horizontal, 15)
                                        .padding(.top, 18)
                                        .allowsHitTesting(false)
                                }
                            }

                        HStack(spacing: 8) {
                            Button {
                                if let value = UIPasteboard.general.string { text = value }
                            } label: {
                                Label("Вставить", systemImage: "doc.on.clipboard")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(p.dim)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Text("\(text.count) символов")
                                .font(.system(size: 9.5))
                                .foregroundColor(p.dim2)
                        }

                        Text("Название — необязательно")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(1.6)
                            .foregroundColor(p.dim)
                            .padding(.top, 4)

                        TextField("Например, основной сервер", text: $name)
                            .font(.system(size: 12))
                            .foregroundColor(p.text)
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(p.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(p.line, lineWidth: 1)
                                    )
                            )

                        if let error = store.addError {
                            Text(error)
                                .font(.system(size: 11))
                                .foregroundColor(p.text.opacity(0.8))
                        }

                        Button {
                            Task {
                                await store.addInput(text, name: name)
                                if store.addError == nil { dismiss() }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if store.addBusy {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(p.buttonFg)
                                        .scaleEffect(0.8)
                                }
                                Text(store.addBusy ? "Загружаем…" : "Добавить")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(p.buttonFg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(p.buttonBg)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(store.addBusy)

                        Text("Поддерживаются ссылки-подписки (base64-список) и отдельные ключи VLESS, VMess, Trojan, Shadowsocks, Hysteria2.")
                            .font(.system(size: 9.5))
                            .foregroundColor(p.dim2)
                            .lineSpacing(2)
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Новая подписка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") { dismiss() }
                        .foregroundColor(p.text)
                }
            }
            .onAppear { store.addError = nil }
        }
    }
}
