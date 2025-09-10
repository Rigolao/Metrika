import SwiftUI
import UIKit

// MARK: - Componentes (Cards)
struct CardPesoView: View {
    @Binding var ultimoPeso: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Último Peso")
                    .font(.headline)
            }
            Text(ultimoPeso)
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct CardHidratacaoView: View {
    @Binding var aguaHoje: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundColor(.cyan)
                Text("Água Hoje")
                    .font(.headline)
            }
            Text(aguaHoje)
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
