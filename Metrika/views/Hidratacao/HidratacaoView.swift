import SwiftUI

struct HidratacaoView: View {
    private let healthKitManager = HealthKitManager()
    
    @State private var aguaConsumida: Double = 0.0
    @State private var metaAgua: Double = 2.0 // Meta de 2 litros
    
    // Novas variáveis de estado para o alerta
    @State private var isShowingCustomAlert = false
    @State private var customAmountString = ""
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Card de Progresso (sem alterações)
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
                    VStack(alignment: .leading, spacing: 15) {
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
                        
                        // Novo botão para quantidade específica
                        BotaoAdicionarAgua(icone: "plus.circle.fill", volume: "Outra quantidade") {
                            isShowingCustomAlert = true
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Hidratação")
        .onAppear(perform: carregarDados)
        .alert("Adicionar Quantidade", isPresented: $isShowingCustomAlert) {
            TextField("Quantidade em ml", text: $customAmountString)
                .keyboardType(.numberPad) // Facilita a digitação de números
            Button("Cancelar", role: .cancel) {
                customAmountString = "" // Limpa o campo ao cancelar
            }
            Button("Salvar") {
                if let amountInML = Double(customAmountString) {
                    let amountInLiters = amountInML / 1000.0
                    adicionarAgua(litros: amountInLiters)
                }
                customAmountString = "" // Limpa o campo após salvar
            }
        } message: {
            Text("Por favor, informe a quantidade de água que você bebeu em mililitros (ml).")
        }
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

