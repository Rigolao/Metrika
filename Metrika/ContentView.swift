import SwiftUI

struct ContentView: View {
    // 1. Criamos uma variável de estado para controlar qual aba está selecionada.
    // O valor inicial '2' corresponde ao .tag(2) da nossa aba de Início.
    @State private var selectedTab = 2
    
    var body: some View {
        // 2. Ligamos a TabView à nossa variável de estado.
        TabView(selection: $selectedTab) {
            
            NavigationView {
                PesoView()
            }
            .tabItem {
                Label("Peso", systemImage: "scalemass.fill")
            }
            .tag(0) // Tag para a primeira aba
            
            NavigationView {
                HidratacaoView()
            }
            .tabItem {
                Label("Hidratação", systemImage: "drop.fill")
            }
            .tag(1) // Tag para a segunda aba
            
            // A aba de Início está no meio
            NavigationView {
                InicioView()
            }
            .tabItem {
                Label("Início", systemImage: "house.fill")
            }
            .tag(2) // Tag para a terceira aba (a inicial)
            
            NavigationView {
                AtividadesView()
            }
            .tabItem {
                Label("Atividades", systemImage: "flame.fill")
            }
            .tag(3) // Tag para a terceira aba (a inicial)
            
            NavigationView {
                ConfiguracoesView()
            }
            .tabItem {
                Label("Configurações", systemImage: "gearshape.fill")
            }
            .tag(4) // Tag para a quinta aba
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

