import SwiftUI
import shared

/**
 * App principal do IrrigaSIM iOS.
 * Inicializa Koin e apresenta a ContentView.
 */
@main
struct IrrigaSIMApp: App {

    init() {
        // Inicializa Koin para iOS
        InitKoinKt.doInitKoin()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(nil) // Usa tema do sistema
        }
    }
}
