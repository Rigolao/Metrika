import SwiftUI
import VisionKit // Para o processamento da imagem da câmara
import HealthKit // Importamos o HealthKit para reconhecer os seus tipos de dados
import Vision // Esta é a linha que faltava

struct InicioView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var ultimoPeso: String = "A carregar..."
    @State private var aguaHoje: String = "A carregar..."
    
    // Estados para controlar a câmara e o alerta
    @State private var isShowingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var pesoReconhecido: Double?
    @State private var isShowingConfirmationAlert = false

    var body: some View {
        // O NavigationView foi REMOVIDO daqui
        ZStack(alignment: .bottomTrailing) {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                // O Text("Resumo de Hoje") foi REMOVIDO
                VStack(spacing: 20) {
                    CardPesoView(ultimoPeso: $ultimoPeso)
                    CardHidratacaoView(aguaHoje: $aguaHoje)
                }
                .padding()
            }
            
            // Botão Flutuante da Câmara
            Button(action: {
                self.isShowingImagePicker = true
            }) {
                Image(systemName: "camera.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 10)
            }
            .padding()
        }
        .navigationTitle("Início") // Este é o título que vai aparecer no topo.
        .onAppear(perform: carregarDados)
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(isPresented: $isShowingImagePicker, onImagePicked: { pickedImage in
                self.inputImage = pickedImage
                self.processarImagem()
            })
        }
        .alert("Confirmar Peso", isPresented: $isShowingConfirmationAlert, presenting: pesoReconhecido) { peso in
            Button("Cancelar", role: .cancel) { }
            Button("Salvar") {
                healthKitManager.saveWeight(peso, date: Date()) { success in
                    if success {
                        print("Peso salvo com sucesso!")
                        carregarDados() // Recarrega os dados para atualizar o card
                    } else {
                        print("Falha ao salvar o peso.")
                    }
                }
            }
        } message: { peso in
            Text("Deseja salvar o peso de \(String(format: "%.1f", peso)) kg?")
        }
    }
    
    private func carregarDados() {
        // CORREÇÃO: Agora processamos o dado de saúde (sample) para formatá-lo como texto.
        healthKitManager.fetchLatestWeight { sample in
            guard let validSample = sample else {
                DispatchQueue.main.async {
                    self.ultimoPeso = "Nenhum registo"
                }
                return
            }

            let weightInKg = validSample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            let formattedWeight = String(format: "%.1f kg", weightInKg)

            DispatchQueue.main.async {
                self.ultimoPeso = formattedWeight
            }
        }
        
        healthKitManager.fetchTodayWaterIntake { totalLitros in
            DispatchQueue.main.async {
                self.aguaHoje = String(format: "%.2f L", totalLitros)
            }
        }
    }
    
    private func processarImagem() {
        guard let inputImage = inputImage else { return }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                print("Erro no reconhecimento de texto: \(error?.localizedDescription ?? "Erro desconhecido")")
                return
            }
            
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            
            for text in recognizedStrings {
                let cleanedText = text.replacingOccurrences(of: ",", with: ".")
                if let number = Double(cleanedText) {
                    DispatchQueue.main.async {
                        self.pesoReconhecido = number
                        self.isShowingConfirmationAlert = true
                    }
                    return
                }
            }
        }
        
        guard let cgImage = inputImage.cgImage else { return }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}

struct InicioView_Previews: PreviewProvider {
    static var previews: some View {
        // Para a pré-visualização, mantemos o NavigationView aqui.
        NavigationView {
            InicioView()
        }
    }
}

