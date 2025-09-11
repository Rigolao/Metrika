import SwiftUI
import Charts // Adicionado para os gráficos
import HealthKit // Adicionado para os tipos de dados

// É necessário manter esta estrutura aqui para o gráfico
struct WaterDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let totalLiters: Double
}

struct HidratacaoView: View {
    @StateObject private var healthKitManager = HealthKitManager()

    @State private var aguaConsumida: Double = 0.0
    @State private var metaAgua: Double = 2.0
    
    // Para o alerta de input personalizado
    @State private var isShowingAlert = false
    @State private var customAmountString = ""
    
    // Para o gráfico
    @State private var waterHistory: [WaterDataPoint] = []
    
    var body: some View {
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

                        HStack(spacing: 12) {
                            BotaoAdicionarAgua(icone: "cup.and.saucer.fill", volume: "250ml") {
                                adicionarAgua(litros: 0.25)
                            }
                            BotaoAdicionarAgua(icone: "waterbottle.fill", volume: "750ml") {
                                adicionarAgua(litros: 0.75)
                            }
                            BotaoAdicionarAgua(icone: "plus.circle.fill", volume: "Outro") {
                                isShowingAlert = true
                            }
                        }
                    }
                    
                    // GRÁFICO DE HIDRATAÇÃO
                    VStack(alignment: .leading) {
                        Text("Consumo de Água (Últimos 30 dias)")
                            .font(.headline)
                        
                        if waterHistory.isEmpty || waterHistory.allSatisfy({ $0.totalLiters == 0 }) {
                            Text("Não há dados de hidratação para exibir.")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 200)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                        } else {
                            Chart(waterHistory) { dataPoint in
                                BarMark(
                                    x: .value("Data", dataPoint.date, unit: .day),
                                    y: .value("Litros (L)", dataPoint.totalLiters)
                                )
                                .foregroundStyle(.cyan)
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel(format: .dateTime.month().day())
                                }
                            }
                            .frame(height: 250)
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Hidratação")
        .onAppear(perform: carregarDados)
        .alert("Adicionar Quantidade", isPresented: $isShowingAlert) {
            TextField("Quantidade em ml", text: $customAmountString)
                .keyboardType(.numberPad)
            Button("Adicionar") {
                if let ml = Double(customAmountString) {
                    adicionarAgua(litros: ml / 1000)
                }
                customAmountString = ""
            }
            Button("Cancelar", role: .cancel) {
                customAmountString = ""
            }
        } message: {
            Text("Insira a quantidade de água que bebeu.")
        }
    }
        
    private func carregarDados() {
        // Carrega o consumo de hoje
        healthKitManager.fetchTodayWaterIntake { totalLitros in
            DispatchQueue.main.async {
                self.aguaConsumida = totalLitros
            }
        }
        
        // Carrega o histórico para o gráfico
        healthKitManager.fetchWaterIntakeHistory { dailyTotals in
            DispatchQueue.main.async {
                self.waterHistory = dailyTotals.map { WaterDataPoint(date: $0.key, totalLiters: $0.value) }.sorted(by: { $0.date < $1.date })
            }
        }
    }
        
    private func adicionarAgua(litros: Double) {
        healthKitManager.saveWaterIntake(liters: litros, date: Date()) { success in
            if success {
                print("Água salva com sucesso!")
                // Recarrega todos os dados para atualizar tanto o card como o gráfico
                DispatchQueue.main.async {
                    self.carregarDados()
                }
            } else {
                print("Falha ao salvar a água.")
            }
        }
    }
}

// O componente BotaoAdicionarAgua permanece o mesmo
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
        NavigationView {
            HidratacaoView()
        }
    }
}

