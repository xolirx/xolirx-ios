import SwiftUI
import UIKit

/// Палитра: только графит, белый и чёрный.
struct Palette {
    let scheme: ColorScheme

    var dark: Bool { scheme == .dark }

    var bg: Color { dark ? Color(white: 0.035) : Color(white: 0.965) }
    var card: Color { dark ? Color(white: 0.075) : Color(white: 0.995) }
    var surface: Color { dark ? Color.white.opacity(0.05) : Color.black.opacity(0.045) }
    var text: Color { dark ? Color(white: 0.96) : Color(white: 0.06) }
    var dim: Color { dark ? Color(white: 0.62) : Color(white: 0.40) }
    var dim2: Color { dark ? Color(white: 0.42) : Color(white: 0.62) }
    var line: Color { dark ? Color.white.opacity(0.12) : Color.black.opacity(0.10) }
    var lineStrong: Color { dark ? Color.white.opacity(0.24) : Color.black.opacity(0.22) }
    var buttonBg: Color { dark ? Color(white: 0.96) : Color(white: 0.07) }
    var buttonFg: Color { dark ? Color(white: 0.04) : Color(white: 1) }
}

struct ArtBackground: View {
    let scheme: ColorScheme
    var body: some View {
        GeometryReader { geo in
            ZStack {
                (scheme == .dark ? Color(white: 0.03) : Color(white: 0.96))
                if let image = UIImage(named: "bg") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .saturation(0)
                        .opacity(scheme == .dark ? 0.55 : 0.16)
                }
                LinearGradient(
                    colors: scheme == .dark
                        ? [Color.black.opacity(0.88), Color.black.opacity(0.55), Color.black.opacity(0.8)]
                        : [Color.white.opacity(0.92), Color.white.opacity(0.72), Color.white.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
}

struct CardBackground: ViewModifier {
    let palette: Palette
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(palette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(palette.line, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func card(_ palette: Palette) -> some View {
        modifier(CardBackground(palette: palette))
    }
}

struct SectionLabel: View {
    let text: String
    let palette: Palette
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .tracking(2.0)
            .foregroundColor(palette.dim)
    }
}

struct MonoActionButton: View {
    let title: String
    let icon: String
    let palette: Palette
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(.system(size: 11.5, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(palette.text.opacity(0.85))
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(palette.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(palette.line, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct SegmentedTabs: View {
    let items: [String]
    @Binding var index: Int
    let palette: Palette

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(items.enumerated()), id: \.offset) { offset, title in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { index = offset }
                } label: {
                    Text(title)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(index == offset ? palette.buttonFg : palette.dim)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(index == offset ? palette.buttonBg : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(palette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(palette.line, lineWidth: 1)
                )
        )
    }
}
