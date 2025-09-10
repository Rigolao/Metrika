import SwiftUI

// MARK: - View Principal com Abas
struct ContentView: View {
    var body: some View {
        TabView {
            // Cada ecrã agora está dentro da sua própria NavigationView
            // para que possa ter a sua própria barra de título.
            NavigationView {
                InicioView()
            }
            .tabItem {
                Label("Início", systemImage: "house.fill")
            }

            NavigationView {
                HidratacaoView()
            }
            .tabItem {
                Label("Hidratação", systemImage: "drop.fill")
            }

            NavigationView {
                RelatoriosView()
            }
            .tabItem {
                Label("Relatórios", systemImage: "chart.bar.xaxis")
            }
            
            NavigationView {
                ConfiguracoesView()
            }
            .tabItem {
                Label("Configurações", systemImage: "gearshape.fill")
            }
        }
        .tint(.blue)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

