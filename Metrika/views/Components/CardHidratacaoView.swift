import SwiftUI
import UIKit

struct CardHidratacaoView: View {
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
