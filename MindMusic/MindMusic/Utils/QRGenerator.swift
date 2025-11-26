import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRGenerator {
    static func image(from string: String, scale: CGFloat = 5) -> Image? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cg = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return Image(decorative: cg, scale: 1, orientation: .up)
    }
}
