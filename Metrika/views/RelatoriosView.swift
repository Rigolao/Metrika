import SwiftUI
import Charts // Importa o framework de gráficos
import HealthKit // Adiciona a referência ao HealthKit

/// Estrutura auxiliar para os dados do gráfico de água, para ser compatível com `Chart`.
struct WaterDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let totalLiters: Double
}

struct RelatoriosView: View {
    private let healthKitManager = HealthKitManager()
    
    @State private var weightHistory: [HKQuantitySample] = []
    @State private var waterHistory: [WaterDataPoint] = []
    
    var body: some View {
        // A NavigationView foi REMOVIDA daqui
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
                
            ScrollView {
                VStack(spacing: 20) {
                    // Card do Gráfico de Peso
                    VStack(alignment: .leading) {
                        Text("Evolução do Peso (Últimos 30 dias)")
                            .font(.headline)
                        
                        if weightHistory.isEmpty {
                            Text("Não há dados de peso para exibir.")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            Chart(weightHistory, id: \.uuid) { sample in
                                let date = sample.startDate
                                let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                                
                                LineMark(
                                    x: .value("Data", date, unit: .day),
                                    y: .value("Peso (kg)", weight)
                                )
                                .foregroundStyle(.blue)
                                
                                PointMark(
                                    x: .value("Data", date, unit: .day),
                                    y: .value("Peso (kg)", weight)
                                )
                                .foregroundStyle(.blue)
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel(format: .dateTime.month().day())
                                }
                            }
                            .frame(height: 250)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    
                    // Card do Gráfico de Hidratação
                    VStack(alignment: .leading) {
                        Text("Consumo de Água (Últimos 30 dias)")
                            .font(.headline)
                        
                        if waterHistory.isEmpty || waterHistory.allSatisfy({ $0.totalLiters == 0 }) {
                            Text("Não há dados de hidratação para exibir.")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 200)
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
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationTitle("Relatórios") // Usamos o título da barra de navegação
        .onAppear(perform: carregarDados)
    }
    
    private func carregarDados() {
        // Carrega o histórico de peso
        healthKitManager.fetchWeightHistory { samples in
            DispatchQueue.main.async {
                self.weightHistory = samples
            }
        }
        
        // Carrega o histórico de consumo de água
        healthKitManager.fetchWaterIntakeHistory { dailyTotals in
            DispatchQueue.main.async {
                // Converte o dicionário para um array e ordena por data para o gráfico
                self.waterHistory = dailyTotals.map { WaterDataPoint(date: $0.key, totalLiters: $0.value) }.sorted(by: { $0.date < $1.date })
            }
        }
    }
}


struct RelatoriosView_Previews: PreviewProvider {
    static var previews: some View {
        // Para a pré-visualização, mantemos o NavigationView aqui.
        NavigationView {
            RelatoriosView()
        }
    }
}

