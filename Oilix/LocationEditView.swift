import SwiftUI
import MapKit

struct LocationEditView: View {
    @Binding var ent: Bool
    @ObservedObject var samples: WaterSampleViewModel
    @Binding var ind: Int
    @Binding var region: MKCoordinateRegion
    @StateObject private var locationManager = LocationManager(startImmediately: false)
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var locationAlert = false
    @State private var usingCurrentLocation = false

    private var coordinate: CLLocationCoordinate2D? {
        guard let lat = Double(latitude), let lon = Double(longitude),
              lat.isFinite, lon.isFinite else { return nil }
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        return CLLocationCoordinate2DIsValid(coordinate) ? coordinate : nil
    }

    var body: some View {
        OilixNavigation {
            Form {
                Section {
                    Map(coordinateRegion: $region)
                        .frame(height: 180)
                        .allowsHitTesting(false)
                        .overlay(Image(systemName: "mappin").font(.title).foregroundColor(.red))
                        .accessibilityLabel("Sample location preview")
                }
                Section(header: Text("Coordinates")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Latitude").font(.subheadline)
                        TextField("Latitude", text: $latitude)
                            .accessibilityIdentifier("location.latitude")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Longitude").font(.subheadline)
                        TextField("Longitude", text: $longitude)
                            .accessibilityIdentifier("location.longitude")
                    }
                }
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                if coordinate == nil {
                    Section {
                        Text("Enter a latitude from -90 to 90 and a longitude from -180 to 180.")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                }
                Section {
                    Button(action: useCurrentLocation) {
                        Label("Use Current Location", systemImage: "location.fill").frame(minHeight: 44)
                    }
                    .disabled(usingCurrentLocation).accessibilityIdentifier("location.current")
                    if usingCurrentLocation { ProgressView("Finding your location...") }
                }
            }
            .oilixKeyboardDismissal()
            .navigationTitle("Edit Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                        .accessibilityIdentifier("location.keyboardDone")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { ent = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let coordinate = coordinate, samples.samples.indices.contains(ind) else { return }
                        samples.samples[ind].location = "\(coordinate.latitude),\(coordinate.longitude)"
                        ent = false
                    }
                    .disabled(coordinate == nil)
                    .accessibilityIdentifier("location.save")
                }
            }
        }
        .onAppear {
            guard samples.samples.indices.contains(ind),
                  let coordinate = History.getLocation(locStr: samples.samples[ind].location) else { return }
            latitude = String(coordinate.latitude)
            longitude = String(coordinate.longitude)
            updatePreview()
        }
        .onChange(of: latitude) { _ in updatePreview() }
        .onChange(of: longitude) { _ in updatePreview() }
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { location in
            if usingCurrentLocation { applyLocation(location) }
        }
        .onReceive(locationManager.$locationStatus) { status in
            if usingCurrentLocation && (status == .denied || status == .restricted) {
                usingCurrentLocation = false; locationManager.stop(); locationAlert = true
            }
        }
        .onDisappear { usingCurrentLocation = false; locationManager.stop() }
        .alert("Location Unavailable", isPresented: $locationAlert) {
            if locationManager.locationStatus == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text("Check location access for Oilix in Settings, then try again when your location is available.")
        }
        .interactiveDismissDisabled()
    }

    private func updatePreview() {
        if let coordinate = coordinate { region.center = coordinate }
    }

    private func useCurrentLocation() {
        usingCurrentLocation = true
        locationManager.start()
        if let location = locationManager.lastLocation, LocationManager.isUsable(location), locationManager.hasAccess {
            applyLocation(location)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            guard usingCurrentLocation else { return }
            usingCurrentLocation = false; locationManager.stop(); locationAlert = true
        }
    }

    private func applyLocation(_ location: CLLocation) {
        guard locationManager.hasAccess, LocationManager.isUsable(location) else { return }
        latitude = String(location.coordinate.latitude)
        longitude = String(location.coordinate.longitude)
        usingCurrentLocation = false
        locationManager.stop()
        updatePreview()
    }
}
