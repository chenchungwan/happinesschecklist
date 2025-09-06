import SwiftUI
import UIKit
import QuartzCore

struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let container = UIView()

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2.0, y: -8)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 1)

        let colors: [UIColor] = [
            .systemPink, .systemYellow, .systemBlue, .systemGreen, .systemOrange, .systemPurple
        ]

        let baseImage = UIImage(named: "Logo")
        let cells: [CAEmitterCell] = colors.map { color in
            let cell = CAEmitterCell()
            cell.birthRate = 8
            cell.lifetime = 4
            cell.lifetimeRange = 1
            cell.velocity = 200
            cell.velocityRange = 80
            cell.yAcceleration = 120
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 8
            cell.spin = 2
            cell.spinRange = 4
            cell.scale = 0.25
            cell.scaleRange = 0.15
            if let img = baseImage {
                let tinted = img.withRenderingMode(.alwaysTemplate)
                let renderer = UIGraphicsImageRenderer(size: img.size)
                let image = renderer.image { ctx in
                    color.set()
                    ctx.fill(CGRect(origin: .zero, size: img.size))
                    tinted.draw(in: CGRect(origin: .zero, size: img.size))
                }
                cell.contents = image.cgImage
            } else {
                cell.contents = UIImage(systemName: "circle.fill")?
                    .withTintColor(color, renderingMode: .alwaysOriginal)
                    .cgImage
            }
            return cell
        }

        emitter.emitterCells = cells
        container.layer.addSublayer(emitter)

        // Stop and remove after a brief celebration window
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            emitter.birthRate = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            emitter.removeFromSuperlayer()
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}


