import SwiftUI
import UIKit

struct CongratsAlertView: View {
    var message: String

    private var logoImage: Image {
        if let img = UIImage(named: "Logo") {
            return Image(uiImage: img)
        } else {
            return Image(systemName: "checkmark.seal.fill")
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                logoImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .foregroundColor(.green)
                Text("Nice work!")
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 12)
            .padding(.horizontal, 32)
        }
        .transition(.scale.combined(with: .opacity))
    }
}


