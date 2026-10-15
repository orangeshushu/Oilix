import SwiftUI
import Alamofire
import MapKit
import ImageIO
import UniformTypeIdentifiers

struct UploadResponse: Decodable {
    let status: Int
    let msg: String
    let meta: Metadata?

    struct Metadata: Decodable {
        let result: String?
    }
}

@MainActor
final class SampleUploadController: ObservableObject {
    @Published private(set) var isBusy = false
    @Published private(set) var status = ""
    @Published private(set) var completedCount = 0
    @Published private(set) var totalCount = 0
    private var request: UploadRequest?
    private var connectionRequest: DataRequest?
    private var generation = 0
    private let network: Alamofire.Session

    init(network: Alamofire.Session = .default) {
        self.network = network
    }

    func start(samples: WaterSampleViewModel, completion: @escaping (Int, [String]) -> Void) {
        guard !isBusy && !samples.isImporting else { return }
        let queue = samples.samples.filter { !$0.online }
        guard !queue.isEmpty else { return }
        isBusy = true
        completedCount = 0
        totalCount = queue.count
        status = "Checking connection..."
        generation += 1
        let generation = generation
        connectionRequest = network.request(cameraURL + "stat", method: .get) { $0.timeoutInterval = 1 }
            .response { response in
                guard self.generation == generation, self.isBusy else { return }
                self.connectionRequest = nil
                if case .success = response.result {
                    self.isBusy = false
                    completion(0, ["Disconnect from \(deviceName) and connect to Wi-Fi or cellular data before uploading."])
                } else {
                    self.send(queue, at: 0, samples: samples, successes: 0, errors: [], completion: completion)
                }
            }
    }

    func cancel() {
        generation += 1
        connectionRequest?.cancel()
        request?.cancel()
        connectionRequest = nil
        request = nil
        isBusy = false
    }

    private func send(_ queue: [WaterSample], at position: Int, samples: WaterSampleViewModel,
                      successes: Int, errors: [String], completion: @escaping (Int, [String]) -> Void) {
        guard isBusy else { return }
        guard position < queue.count else {
            request = nil
            isBusy = false
            completion(successes, errors)
            return
        }
        let sample = queue[position]
        let generation = generation
        status = "Uploading and analyzing image \(position + 1) of \(queue.count)..."
        // Use an immutable batch and stable sample IDs while encoding away from the UI thread.
        DispatchQueue.global(qos: .userInitiated).async {
            let imageData = sample.image.jpegData(compressionQuality: 1)
            DispatchQueue.main.async {
                guard self.generation == generation, self.isBusy else { return }
                guard let imageData = imageData else {
                    self.finishImage(queue, at: position, samples: samples, successes: successes,
                                     errors: errors + ["Image \(position + 1) could not be read."], completion: completion)
                    return
                }
                self.request = self.network.upload(multipartFormData: { form in
                    form.append(imageData, withName: "photo", fileName: "\(sample.id.uuidString).jpeg", mimeType: "image/jpeg")
                    form.append(Data(sample.location.utf8), withName: "gps")
                    form.append(Data(sample.note.utf8), withName: "notes")
                }, to: serverURL + "photoupload")
                .validate(statusCode: 200..<300)
                .responseDecodable(of: UploadResponse.self) { response in
                    guard self.generation == generation, self.isBusy else { return }
                    switch response.result {
                    case .success(let result):
                        if result.status == 0 {
                            if let index = samples.samples.firstIndex(where: { $0.id == sample.id }) {
                                samples.samples[index].result = result.meta?.result ?? ""
                                samples.samples[index].online = true
                            }
                            self.finishImage(queue, at: position, samples: samples, successes: successes + 1,
                                             errors: errors, completion: completion)
                        } else {
                            self.finishImage(queue, at: position, samples: samples, successes: successes,
                                             errors: errors + ["Image \(position + 1): \(result.msg)"], completion: completion)
                        }
                    case .failure:
                        self.finishImage(queue, at: position, samples: samples, successes: successes,
                                         errors: errors + ["Image \(position + 1): Upload could not be confirmed. Check History before retrying."],
                                         completion: completion)
                    }
                }
            }
        }
    }

    private func finishImage(_ queue: [WaterSample], at position: Int, samples: WaterSampleViewModel,
                             successes: Int, errors: [String], completion: @escaping (Int, [String]) -> Void) {
        completedCount = position + 1
        send(queue, at: position + 1, samples: samples, successes: successes, errors: errors, completion: completion)
    }
}

struct SamplingView: View {
    @ObservedObject var se: Session
    @Binding var tabSelection: Int
    @ObservedObject var samples: WaterSampleViewModel
    @ObservedObject var upload: SampleUploadController
    @StateObject private var locationManager = LocationManager(startImmediately: false)
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.verticalSizeClass) private var heightClass
    @State private var previewN = 0
    @State private var picker = false
    @State private var capture = false
    @State private var noteSheet = false
    @State private var locationSheet = false
    @State private var instructions = false
    @State private var filePicker = false
    @State private var deleteAlert = false
    @State private var clearAlert = false
    @State private var messageAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var locationSampleID: UUID?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )

    private var currentSample: WaterSample? {
        samples.samples.indices.contains(previewN) ? samples.samples[previewN] : nil
    }

    private var pendingCount: Int { samples.samples.filter { !$0.online }.count }
    private var inlineUploadBar: Bool { heightClass == .compact || typeSize.isAccessibilitySize }

    var body: some View {
        OilixNavigation {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if samples.isImporting {
                        HStack(alignment: .top, spacing: 12) {
                            ProgressView()
                            Text(samples.importStatus).font(.subheadline)
                            Spacer(minLength: 0)
                            Button("Cancel") { samples.cancelImport() }.frame(minHeight: 44)
                        }
                    }
                    if let sample = currentSample {
                        review(sample)
                        if inlineUploadBar { uploadBar }
                    } else {
                        welcome.disabled(samples.isImporting)
                    }
                }
                .padding(20)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Sampling")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button { instructions = true } label: {
                            Label("Instructions", systemImage: "book")
                        }
                        .accessibilityIdentifier("sampling.menuInstructions")
                        Link(destination: URL(string: "https://wateroil.web.app")!) {
                            Label("Web Database", systemImage: "arrow.up.right.square")
                        }
                        if samples.count > 0 {
                            Button(role: .destructive) { clearAlert = true } label: {
                                Label("Clear Selected Images", systemImage: "trash")
                            }
                            .disabled(upload.isBusy || samples.isImporting)
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal").font(.system(size: 18))
                    }
                    .accessibilityLabel("Sampling menu")
                    .accessibilityIdentifier("sampling.menu")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { picker = true } label: { Label("Photo Library", systemImage: "photo.on.rectangle") }
                        Button { filePicker = true } label: { Label("Files", systemImage: "folder") }
                        Button { capture = true } label: { Label(deviceName, systemImage: "camera") }
                    } label: {
                        Image(systemName: "plus").font(.system(size: 18))
                    }
                    .disabled(upload.isBusy || samples.isImporting)
                    .accessibilityLabel("Add images")
                    .accessibilityIdentifier("sampling.addImages")
                    .oilixTourTarget(.images, enabled: currentSample != nil)
                    .oilixTourTarget(.camera, enabled: currentSample != nil)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if samples.count > 0 && !inlineUploadBar { uploadBar }
            }
        }
        .sheet(isPresented: $picker) {
            ImagePicker(picker: $picker, samples: samples, onImportError: { message in
                alertTitle = "Import Summary"; alertMessage = message; messageAlert = true
            })
        }
        .sheet(isPresented: $capture) { CameraView(samples: samples, picker: $picker, isPresented: $capture) }
        .sheet(isPresented: $noteSheet) { NoteView(samples: samples, i: $previewN, noteSheet: $noteSheet) }
        .sheet(isPresented: $locationSheet) {
            LocationEditView(ent: $locationSheet, samples: samples, ind: $previewN, region: $region)
        }
        .oilixTourSurface(tab: 2)
        .sheet(isPresented: $instructions) { InstructionsView() }
        .fileImporter(isPresented: $filePicker, allowedContentTypes: [.image], allowsMultipleSelection: true) {
            importFiles($0)
        }
        .confirmationDialog(currentSample?.online == true ? "Remove this preview?" : "Remove this image?",
                            isPresented: $deleteAlert, titleVisibility: .visible) {
            Button("Remove", role: .destructive) { deleteCurrentImage() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(currentSample?.online == true
                 ? "The uploaded image will remain in History."
                 : "This image will be removed from this upload. Your original photo will be kept.")
        }
        .confirmationDialog("Clear selected images?", isPresented: $clearAlert, titleVisibility: .visible) {
            Button("Clear", role: .destructive) {
                samples.deleteAll(); previewN = 0; locationSampleID = nil
                locationManager.stop()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This clears the current selection. Original photos and uploaded history will be kept.")
        }
        .alert(alertTitle, isPresented: $messageAlert) {
            if alertTitle == "Location Unavailable", locationManager.locationStatus == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
            }
            Button("OK", role: .cancel) { }
        } message: { Text(alertMessage) }
        .onChange(of: samples.count) { _ in clampPreviewIndex() }
        .onReceive(se.$isLoggedIn) { loggedIn in
            if !loggedIn { upload.cancel(); samples.cancelImport() }
        }
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { location in
            applyCurrentLocation(location)
        }
        .onDisappear { locationManager.stop(); locationSampleID = nil }
        .onReceive(locationManager.$locationStatus) { status in
            if locationSampleID != nil && (status == .denied || status == .restricted) {
                locationSampleID = nil
                alertTitle = "Location Unavailable"
                alertMessage = "Enable location access for Oilix in Settings to use your current location."
                messageAlert = true
            }
        }
    }

    private var welcome: some View {
        VStack(spacing: 24) {
            Button { capture = true } label: {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80, weight: .regular))
                    .frame(width: 112, height: 112)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Capture with \(deviceName)")
            .accessibilityIdentifier("sampling.cameraShortcut")
            .oilixTourTarget(.camera)
            Text("New Sample").font(.title2.bold()).multilineTextAlignment(.center)
            Button { picker = true } label: { Label("Choose Images", systemImage: "photo.on.rectangle") }
                .buttonStyle(PrimaryActionStyle())
                .accessibilityIdentifier("sampling.chooseImages")
                .oilixTourTarget(.images)
            VStack(spacing: 0) {
                Button { filePicker = true } label: { sourceRow("Choose from Files", symbol: "folder") }
                    .accessibilityIdentifier("sampling.chooseFiles")
                Divider()
                Button { capture = true } label: { sourceRow("Capture with \(deviceName)", symbol: "camera") }
                    .accessibilityIdentifier("sampling.openCamera")
            }.buttonStyle(.plain)
            NavigationLink(destination: InstructionDetailView(topic: .preparation)) {
                Label("Prepare a sample", systemImage: "testtube.2").font(.subheadline).frame(minHeight: 44)
            }.accessibilityIdentifier("sampling.instructions")
        }
        .padding(.top, 24)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity)
    }

    private func sourceRow(_ title: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 20)).foregroundColor(.accentColor)
                .frame(width: 28)
            Text(title).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }.padding(.vertical, 12).frame(minHeight: 44).contentShape(Rectangle())
    }

    private func review(_ sample: WaterSample) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button { previewN -= 1 } label: {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .disabled(previewN == 0).accessibilityLabel("Previous image")
                Spacer()
                Text("Image \(previewN + 1) of \(samples.count)")
                    .font(.subheadline.weight(.medium)).monospacedDigit()
                    .accessibilityIdentifier("sampling.imageCount")
                Spacer()
                Button { previewN += 1 } label: {
                    Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .disabled(previewN >= samples.count - 1).accessibilityLabel("Next image")
            }.buttonStyle(.plain)
            SamplePreview(image: sample.image).accessibilityLabel("Selected sample image")
            if samples.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(samples.samples.enumerated()), id: \.element.id) { index, item in
                            Button { previewN = index } label: {
                                Image(uiImage: item.image).resizable().scaledToFill()
                                    .frame(width: 48, height: 48).clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(index == previewN ? Color.accentColor : Color.clear, lineWidth: 2))
                            }
                            .accessibilityLabel("Image \(index + 1)")
                            .accessibilityAddTraits(index == previewN ? .isSelected : [])
                        }
                    }.padding(4)
                }
            }
            if typeSize.isAccessibilitySize {
                VStack(spacing: 0) { imageActions(sample) }
            } else {
                HStack(spacing: 8) { imageActions(sample) }
            }
            Divider()
            VStack(alignment: .leading, spacing: 0) {
                metadata("Captured", symbol: "calendar", value: sample.time)
                metadata("Location", symbol: "location", value: locationDescription(sample.location))
                if !sample.online && locationDescription(sample.location) == "No GPS data" {
                    Button(action: useCurrentLocation) {
                        Label(locationSampleID == nil ? "Use Current Location" : "Getting Location...",
                              systemImage: "location.fill").font(.subheadline).frame(minHeight: 44)
                    }.disabled(locationSampleID != nil)
                }
                metadata("Notes", symbol: "note.text", value: sample.note.isEmpty ? "No notes added" : sample.note)
            }
            if sample.online {
                Divider()
                Label("Uploaded", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium)).foregroundColor(.green)
                metadata("Prediction", symbol: "testtube.2",
                         value: sample.result.isEmpty ? "Result not available" : "\(sample.result) mg/L")
            }
        }
        .disabled(upload.isBusy || samples.isImporting)
    }

    @ViewBuilder
    private func imageActionLabel(_ title: String, symbol: String) -> some View {
        if typeSize.isAccessibilitySize {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.system(size: 20)).frame(width: 24)
                Text(title).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }.frame(maxWidth: .infinity, minHeight: 44).padding(.vertical, 8).contentShape(Rectangle())
        } else {
            VStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 20))
                Text(title).font(.caption.weight(.medium))
            }.frame(maxWidth: .infinity, minHeight: 60).contentShape(Rectangle())
        }
    }

    @ViewBuilder
    private func imageActions(_ sample: WaterSample) -> some View {
        Button {
            if se.deleteConfirm { deleteAlert = true } else { deleteCurrentImage() }
        } label: { imageActionLabel("Remove", symbol: "trash") }
        .buttonStyle(.plain).foregroundColor(.red)
        .accessibilityLabel(sample.online ? "Remove preview" : "Delete image")
        .accessibilityIdentifier("sampling.deleteImage")
        Button { noteSheet = true } label: { imageActionLabel("Note", symbol: "note.text") }
            .buttonStyle(.plain).disabled(sample.online)
            .accessibilityLabel("Edit note").accessibilityIdentifier("sampling.editNote")
        Button {
            locationSampleID = nil
            region.center = History.getLocation(locStr: sample.location)
                ?? locationManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            locationSheet = true
        } label: { imageActionLabel("Location", symbol: "location.viewfinder") }
        .buttonStyle(.plain).disabled(sample.online)
        .accessibilityLabel("Edit location").accessibilityIdentifier("sampling.editLocation")
    }

    private func metadata(_ title: String, symbol: String, value: String) -> some View {
        SampleMetadataRow(title: title, symbol: symbol, value: value)
    }

    private var uploadBar: some View {
        VStack(spacing: 12) {
            if upload.isBusy {
                ProgressView(value: Double(upload.completedCount), total: Double(max(upload.totalCount, 1)))
                HStack {
                    ProgressView()
                    Text(upload.status).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            } else if pendingCount > 0 {
                Button {
                    upload.start(samples: samples) { successes, errors in
                        alertTitle = errors.isEmpty ? "Upload Complete" : "Upload Summary"
                        let summary = "\(successes) of \(upload.totalCount) images uploaded."
                        alertMessage = errors.isEmpty ? summary : summary + "\n\n" + errors.joined(separator: "\n")
                        messageAlert = true
                    }
                } label: {
                    Label("Upload \(pendingCount) \(pendingCount == 1 ? "Image" : "Images")", systemImage: "icloud.and.arrow.up")
                }
                .buttonStyle(PrimaryActionStyle())
                .disabled(locationSampleID != nil || samples.isImporting)
                .accessibilityIdentifier("sampling.upload")
            } else {
                Button { tabSelection = 1 } label: {
                    Label("View Upload History", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(PrimaryActionStyle())
                Button("Start New Sample") { clearAlert = true }.frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }

    private func useCurrentLocation() {
        guard let sample = currentSample, !sample.online else { return }
        locationSampleID = sample.id
        locationManager.start()
        if let location = locationManager.lastLocation, LocationManager.isUsable(location) {
            applyCurrentLocation(location)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            guard locationSampleID == sample.id else { return }
            locationSampleID = nil
            locationManager.stop()
            alertTitle = "Location Unavailable"
            alertMessage = "Your location could not be determined. Try again or enter coordinates using Edit Location."
            messageAlert = true
        }
    }

    private func applyCurrentLocation(_ location: CLLocation) {
        guard let id = locationSampleID,
              locationManager.hasAccess, LocationManager.isUsable(location) else { return }
        locationSampleID = nil
        locationManager.stop()
        guard let index = samples.samples.firstIndex(where: { $0.id == id }), !samples.samples[index].online else { return }
        samples.samples[index].location = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
    }

    private func locationDescription(_ value: String) -> String {
        guard let coordinate = History.getLocation(locStr: value), CLLocationCoordinate2DIsValid(coordinate),
              coordinate.latitude != 0 || coordinate.longitude != 0 else { return "No GPS data" }
        return String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
    }

    private func deleteCurrentImage() {
        guard !upload.isBusy else { return }
        if currentSample?.id == locationSampleID {
            locationSampleID = nil
            locationManager.stop()
        }
        samples.delete(previewN)
        clampPreviewIndex()
    }

    private func clampPreviewIndex() {
        previewN = samples.count == 0 ? 0 : min(max(previewN, 0), samples.count - 1)
    }

    private func importFiles(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty, !samples.isImporting, !upload.isBusy else { return }
            let generation = samples.beginImport(total: urls.count)
            importFile(urls, at: 0, failed: 0, generation: generation)
        case .failure:
            alertTitle = "Import Failed"
            alertMessage = "Oilix couldn't read the selected file. Choose the file again to retry."
            messageAlert = true
        }
    }

    private func importFile(_ urls: [URL], at index: Int, failed: Int, generation: Int) {
        guard samples.isImporting, samples.importGeneration == generation, index < urls.count else { return }
        let url = urls[index]
        let accessed = url.startAccessingSecurityScopedResource()
        DispatchQueue.global(qos: .userInitiated).async {
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            let values = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
            let fallbackDate = values?.creationDate ?? values?.contentModificationDate ?? Date()
            let sample = (try? Data(contentsOf: url)).flatMap { SampleImageReader.read($0, fallbackDate: fallbackDate) }
            DispatchQueue.main.async {
                guard samples.isImporting, samples.importGeneration == generation else { return }
                if let sample = sample { samples.add(image: sample.image, location: sample.location, times: sample.date) }
                let failures = failed + (sample == nil ? 1 : 0)
                samples.updateImport(completed: index + 1, total: urls.count, generation: generation)
                if index + 1 < urls.count { importFile(urls, at: index + 1, failed: failures, generation: generation) }
                else if failures > 0 {
                    alertTitle = "Import Summary"
                    alertMessage = "\(urls.count - failures) of \(urls.count) images imported. Choose the unreadable files again to retry."
                    messageAlert = true
                }
            }
        }
    }
}
