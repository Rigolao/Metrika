import SwiftUI

struct InicioView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    
    // Estados para a UI
    @State private var pesoValor: String = "---"
    @State private var pesoData: String = "A carregar..."
    @State private var aguaConsumida: Double = 0.0
    @State private var metaAgua: Double = 2.0 // Meta de exemplo: 2 litros

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    PesoCardView(peso: $pesoValor, data: $pesoData)
                    
                    HidratacaoCardView(
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
    }
}

// MARK: - Componentes (Cards)
// Mantenha os seus componentes de Card aqui ou num ficheiro separado.
struct PesoCardView: View {
    @Binding var peso: String
    @Binding var data: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                Text("Último Peso Registado")
                    .font(.headline)
            }
            
            Text(peso)
                .font(.system(size: 40, weight: .bold))
            + Text(" kg")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.gray)
            
            Text(data)
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
    }
}

struct HidratacaoCardView: View {
    var progresso: Double
    var meta: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                Text("Hidratação Diária")
                    .font(.headline)
            }
            
            ProgressView(value: progresso)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .padding(.vertical, 5)

            Text(meta)
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
    }
}

struct InicioView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InicioView()
        }
    }
}

