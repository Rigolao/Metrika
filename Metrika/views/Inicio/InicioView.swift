import SwiftUI

struct InicioView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    
    // Estados para a UI
    @State private var pesoValor: String = "---"
    @State private var pesoData: String = "A carregar..."
    @State private var aguaConsumida: Double = 0.0
    @State private var metaAgua: Double = 2.0 // Meta de exemplo: 2 litros
    
    // (NOVOS) Estados para os dados de atividade
    @State private var exerciseMinutes: Double = 0
    @State private var activeCalories: Double = 0

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    // (NOVO) Cards de Atividade
                    HStack(spacing: 15) {
                        SummaryCard(title: "Minutos", value: "\(Int(exerciseMinutes))", unit: "min", icon: "flame.fill", color: .orange)
                        SummaryCard(title: "Calorias", value: "\(Int(activeCalories))", unit: "kcal", icon: "heart.fill", color: .red)
                    }
                    
                    // (CORREÇÃO) Usamos o $ para passar o binding para a View do card.
                    PesoCardView(peso: $pesoValor, data: $pesoData)
                    
                    CardHidratacaoView(
                        progresso: aguaConsumida / metaAgua,
                        meta: "\(String(format: "%.1f", aguaConsumida))L de \(String(format: "%.0f", metaAgua))L"
                    )
                }
                .padding()
            }
        }
        .navigationTitle("Resumo de Hoje")
        .onAppear(perform: carregarDadosDeSaude)
    }
    
    private func carregarDadosDeSaude() {
        // Carregar Peso
        healthKitManager.fetchLatestWeight { sample in
            guard let sample = sample else {
                DispatchQueue.main.async {
                    self.pesoData = "Nenhum registo encontrado"
                }
                return
            }
            
            let weightInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            let formattedWeight = String(format: "%.1f", weightInKg)
            let formattedDate = sample.endDate.formatted(date: .abbreviated, time: .shortened)
            
            DispatchQueue.main.async {
                self.pesoValor = formattedWeight
                self.pesoData = formattedDate
            }
        }
        
        // Carregar Hidratação
        healthKitManager.fetchTodayWaterIntake { totalLitros in
            DispatchQueue.main.async {
                self.aguaConsumida = totalLitros
            }
        }
        
        // (NOVO) Carregar Dados de Atividade
        healthKitManager.fetchTodayExerciseTime { minutes in
            DispatchQueue.main.async { self.exerciseMinutes = minutes }
        }
        
        healthKitManager.fetchTodayActiveEnergy { calories in
            DispatchQueue.main.async { self.activeCalories = calories }
        }
    }
}

struct InicioView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InicioView()
        }
    }
}

