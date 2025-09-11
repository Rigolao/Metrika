import SwiftUI
import Vision
import UIKit

struct PesoView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    
    // Estados para a UI
    @State private var pesoValor: String = "---"
    @State private var pesoData: String = "A carregar..."
    
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
    }
    
    // MARK: - Lógica da Câmara e Vision
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
