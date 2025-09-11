import SwiftUI
import Vision
import UIKit
import Charts // Adicionado para os gráficos
import HealthKit // Adicionado para os tipos de dados

struct PesoView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    
    // Estados para a UI
    @State private var pesoValor: String = "---"
    @State private var pesoData: String = "A carregar..."
    @State private var weightHistory: [HKQuantitySample] = [] // Para o gráfico
    
    // Estados para controlar o fluxo da câmara
    @State private var isShowingCamera = false
    @State private var detectedWeightString: String? = nil
    @State private var isShowingAlert = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    PesoCardView(peso: $pesoValor, data: $pesoData)
                    
                    // GRÁFICO DE PESO MOVIDO PARA AQUI
                    VStack(alignment: .leading) {
                        Text("Evolução do Peso (Últimos 30 dias)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if weightHistory.isEmpty {
                            Text("Não há dados de peso para exibir.")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 200)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
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
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            
            // Botão da Câmara
            Button(action: {
                self.isShowingCamera = true
            }) {
                Image(systemName: "camera.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(20)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 10)
            }
            .padding()
        }
        .navigationTitle("Peso")
        .onAppear(perform: carregarDadosDeSaude)
        .sheet(isPresented: $isShowingCamera) {
            ImagePicker(isPresented: self.$isShowingCamera) { image in
                self.processImage(image)
            }
        }
        .alert("Confirmar Peso", isPresented: $isShowingAlert, presenting: detectedWeightString) { weightString in
            Button("Cancelar", role: .cancel) { }
            Button("Salvar") {
                saveDetectedWeight(weightString)
            }
        } message: { weightString in
            Text("Deseja salvar o peso de \(weightString) kg no Apple Saúde?")
        }
    }
    
    // MARK: - Funções de Dados
    private func carregarDadosDeSaude() {
        // Carrega o último peso para o card
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
        
        // Carrega o histórico de peso para o gráfico
        healthKitManager.fetchWeightHistory { samples in
            DispatchQueue.main.async {
                self.weightHistory = samples
            }
        }
    }
    
    // MARK: - Lógica da Câmara e Vision (sem alterações)
    private func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else { return }
            
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            
            if let foundWeight = findWeightValue(from: recognizedStrings) {
                DispatchQueue.main.async {
                    self.detectedWeightString = foundWeight
                    self.isShowingAlert = true
                }
            } else {
                print("Nenhum valor de peso válido encontrado na imagem.")
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Não foi possível realizar o reconhecimento de texto: \(error)")
            }
        }
    }
    
    private func findWeightValue(from strings: [String]) -> String? {
        let regex = try! NSRegularExpression(pattern: "\\b([0-9]{1,3}[,.][0-9]{1,2})\\b|\\b([0-9]{2,3})\\b")
        
        for string in strings {
            let cleanString = string.replacingOccurrences(of: " ", with: "")
            if let match = regex.firstMatch(in: cleanString, options: [], range: NSRange(location: 0, length: cleanString.utf16.count)) {
                if let range = Range(match.range, in: cleanString) {
                    return String(cleanString[range]).replacingOccurrences(of: ",", with: ".")
                }
            }
        }
        return nil
    }
    
    private func saveDetectedWeight(_ weightString: String) {
        guard let weightValue = Double(weightString) else {
            print("Não foi possível converter \(weightString) para um número.")
            return
        }
        
        healthKitManager.saveWeight(weightValue, date: Date()) { success in
            if success {
                print("Peso salvo com sucesso!")
                self.carregarDadosDeSaude()
            } else {
                print("Falha ao salvar o peso.")
            }
        }
    }
}


struct PesoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PesoView()
        }
    }
}

