import SwiftUI

struct ConfiguracoesView: View {
    // A variável @AppStorage salva a preferência do utilizador permanentemente no dispositivo.
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        Form {
            Section(header: Text("Aparência")) {
                Toggle(isOn: $isDarkMode) {
                    Text("Modo Escuro")
                }
            }
        }
        .navigationTitle("Configurações") // Define o título na barra de navegação
    }
}

struct ConfiguracoesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ConfiguracoesView()
        }
    }
}
