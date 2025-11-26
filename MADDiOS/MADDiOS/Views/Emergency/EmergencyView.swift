import SwiftUI
import MapKit

struct EmergencyContact: Identifiable {
    let id = UUID()
    let name: String
    let relationship: String
    let phone: String
    let coordinate: CLLocationCoordinate2D
}

struct EmergencyView: View {
    private let contacts: [EmergencyContact] = [
        EmergencyContact(
            name: "Mother",
            relationship: "Mother",
            phone: "+94 71 123 4567",
            coordinate: CLLocationCoordinate2D(latitude: 7.0917, longitude: 79.9994) // Gampaha
        ),
        EmergencyContact(
            name: "Father",
            relationship: "Father",
            phone: "+94 77 234 5678",
            coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612) // Colombo
        ),
        EmergencyContact(
            name: "Friend",
            relationship: "Friend",
            phone: "+94 76 345 6789",
            coordinate: CLLocationCoordinate2D(latitude: 7.2906, longitude: 80.6337) // Kandy
        )
    ]

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 7.15, longitude: 80.25),
        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
    )
    @GestureState private var isInteractingWithMap: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Contacts list
                ForEach(contacts) { contact in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.name)
                                .font(.headline)
                            Text(contact.relationship)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(contact.phone)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        if let url = URL(string: "tel://" + contact.phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                            Link(destination: url) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }

                // Map with annotations
                VStack(alignment: .leading, spacing: 8) {
                    Text("Locations")
                        .font(.headline)
                    Map(coordinateRegion: $region, annotationItems: contacts) { item in
                        MapAnnotation(coordinate: item.coordinate) {
                            VStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.red)
                                Text(item.name)
                                    .font(.caption)
                                    .padding(4)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    // Track gestures so the ScrollView doesn't intercept them while interacting with the map
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .updating($isInteractingWithMap) { _, state, _ in
                                state = true
                            }
                    )
                }
            }
            .padding()
            .contentShape(Rectangle())
        }
        .scrollIndicators(.visible)
        .scrollDisabled(isInteractingWithMap)
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle("Emergency")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 12) }
    }
}

#Preview {
    NavigationStack { EmergencyView() }
}
