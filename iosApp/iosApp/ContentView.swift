import SwiftUI
import shared

/**
 * ContentView principal que integra o Compose Multiplatform.
 */
struct ContentView: View {

    var body: some View {
        ComposeView()
            .ignoresSafeArea(.all, edges: .bottom)
    }
}

/**
 * UIViewRepresentable para integrar Compose no SwiftUI.
 */
struct ComposeView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        // Cria o UIViewController do Compose
        // O shared module fornece a UI via Compose Multiplatform
        let controller = ComposeUIViewControllerKt.MainViewController()
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Atualização se necessário
    }
}

#Preview {
    ContentView()
}
