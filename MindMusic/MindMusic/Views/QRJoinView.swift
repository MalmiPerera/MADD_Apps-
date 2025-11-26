import SwiftUI

struct QRJoinView: View {
    @State private var roomCode: String = "mind-calm-001"
    @State private var useAssetQR: Bool = true

    private var joinURL: String {
        "https://mindmusic.app/join/\(roomCode)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Karaoke Join QR")
                    .font(.title2.bold())
                Text("Friends can scan this to join your karaoke session.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                qrImageView
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                HStack {
                    TextField("Room code", text: $roomCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(
                            // cross-platform friendly background
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.15))
                        )
                    Button("Regenerate") { useAssetQR = false }
                        .buttonStyle(.borderedProminent)
                }
                
                #if !os(tvOS)
                ShareLink(item: URL(string: joinURL)!) {
                    Label("Share Join Link", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                #endif

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tips")
                        .font(.headline)
                    Text("- Show this QR full screen for easier scanning.\n- Use Regenerate to create a dynamic QR if the asset isn't available.\n- You can also share the link directly.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .background(
            LinearGradient(colors: [.mint.opacity(0.2), .teal.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
        .onAppear {
            if UIImage(named: "karaoke_qr") == nil { useAssetQR = false }
        }
        #if !os(tvOS)
        .navigationTitle("QR")
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder
    private var qrImageView: some View {
        if useAssetQR, let ui = UIImage(named: "karaoke_qr") {
            Image(uiImage: ui)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(maxWidth: 260, maxHeight: 260)
        } else if let img = QRGenerator.image(from: joinURL, scale: 8) {
            img
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(maxWidth: 260, maxHeight: 260)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 240, height: 240)
                .overlay(Text("QR unavailable").foregroundStyle(.secondary))
        }
    }
}

#Preview { QRJoinView() }
