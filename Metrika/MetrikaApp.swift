import SwiftUI

@main
struct MetrikaApp: App {
    // Lê a preferência guardada pelo utilizador
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Aplica o tema (claro ou escuro) a toda a aplicação
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
