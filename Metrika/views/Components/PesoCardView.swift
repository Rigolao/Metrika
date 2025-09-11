import SwiftUI
import UIKit

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
