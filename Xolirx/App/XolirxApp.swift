import SwiftUI

@main
struct XolirxApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(store)
                .preferredColorScheme(preferredScheme)
                .tint(store.theme == .light ? Color.black : Color.white)
        }
    }

    private var preferredScheme: ColorScheme? {
        switch store.theme {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}
