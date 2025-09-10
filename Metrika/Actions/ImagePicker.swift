import SwiftUI

/// Uma View que encapsula o UIImagePickerController do UIKit para ser usada no SwiftUI.
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        // Checa se a câmera está disponível, senão usa a galeria (útil para o simulador)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            print("Câmera não disponível. Usando a galeria de fotos como fallback.")
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    // O Coordinator atua como uma ponte entre o UIKit (ImagePicker) e o SwiftUI.
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                // Devolve a imagem capturada para a nossa View em SwiftUI.
                parent.onImagePicked(uiImage)
            }
            // Fecha a câmara.
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Fecha a câmara se o utilizador cancelar.
            parent.isPresented = false
        }
    }
}
