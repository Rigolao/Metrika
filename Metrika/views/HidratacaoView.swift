import SwiftUI

struct HidratacaoView: View {
    private let healthKitManager = HealthKitManager()
    
    @State private var aguaConsumida: Double = 0.0
    @State private var metaAgua: Double = 2.0 // Meta de 2 litros
    
    var body: some View {
        // A NavigationView foi REMOVIDA daqui
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
                
            ScrollView {
                VStack(spacing: 20) {
                    // Card de Progresso
                    VStack {
                        Text("Consumo de Hoje")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%.2f L", aguaConsumida))
                            .font(.system(size: 50, weight: .bold))
                            
                        ProgressView(value: aguaConsumida, total: metaAgua)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(x: 1, y: 4, anchor: .center)
                            .padding(.vertical, 10)
                            
                        Text(String(format: "Meta: %.1f L", metaAgua))
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    
                    // Botões de Ação
                    VStack(alignment: .leading) {
                        Text("Adicionar Água")
                            .font(.title2)
                            .fontWeight(.semibold)

                        HStack(spacing: 20) {
                            BotaoAdicionarAgua(icone: "cup.and.saucer.fill", volume: "250ml") {
                                adicionarAgua(litros: 0.25)
                            }
                            BotaoAdicionarAgua(icone: "waterbottle.fill", volume: "750ml") {
                                adicionarAgua(litros: 0.75)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Hidratação") // Usamos o título da barra de navegação
        .onAppear(perform: carregarDados)
    }
    
    private func carregarDados() {
        healthKitManager.fetchTodayWaterIntake { totalLitros in
            DispatchQueue.main.async {
                self.aguaConsumida = totalLitros
            }
        }
    }
    
    private func adicionarAgua(litros: Double) {
        healthKitManager.saveWaterIntake(liters: litros, date: Date()) { success in
            if success {
                print("Água salva com sucesso!")
                // Atualiza o valor na UI
                DispatchQueue.main.async {
                    self.aguaConsumida += litros
                }
            } else {
                print("Falha ao salvar a água.")
            }
        }
    }
}

// MARK: - Componente Botão Reutilizável
struct BotaoAdicionarAgua: View {
    let icone: String
    let volume: String
    let acao: () -> Void
    
    var body: some View {
        Button(action: acao) {
            VStack {
                Image(systemName: icone)
                    .font(.largeTitle)
                Text(volume)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HidratacaoView_Previews: PreviewProvider {
    static var previews: some View {
        // Para a pré-visualização, mantemos o NavigationView aqui.
        NavigationView {
            HidratacaoView()
        }
    }
}

