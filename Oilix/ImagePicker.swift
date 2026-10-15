import SwiftUI
import PhotosUI
import ImageIO
import UniformTypeIdentifiers

struct ImportedSample {
    let image: UIImage
    let location: String
    let date: Date
}

enum SampleImageReader {
    static func read(_ data: Data, fallbackDate: Date = Date()) -> ImportedSample? {
        guard let image = UIImage(data: data) else { return nil }
        let source = CGImageSourceCreateWithData(data as CFData, nil)
        let metadata = source.flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) as? [CFString: Any] }
        var location = "0,0"
        if let gps = metadata?[kCGImagePropertyGPSDictionary] as? [CFString: Any],
           let lat = gps[kCGImagePropertyGPSLatitude] as? NSNumber,
           let lon = gps[kCGImagePropertyGPSLongitude] as? NSNumber {
            let latitude = lat.doubleValue * ((gps[kCGImagePropertyGPSLatitudeRef] as? String)?.uppercased() == "S" ? -1 : 1)
            let longitude = lon.doubleValue * ((gps[kCGImagePropertyGPSLongitudeRef] as? String)?.uppercased() == "W" ? -1 : 1)
            let value = "\(latitude),\(longitude)"
            if History.getLocation(locStr: value) != nil { location = value }
        }
        let exif = metadata?[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = metadata?[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        let rawDate = exif?[kCGImagePropertyExifDateTimeOriginal] as? String ?? tiff?[kCGImagePropertyTIFFDateTime] as? String
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        let date = rawDate.flatMap { formatter.date(from: $0) } ?? fallbackDate
        return ImportedSample(image: image, location: location, date: date)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var picker: Bool
    @ObservedObject var samples: WaterSampleViewModel
    var onImportError: (String) -> Void = { _ in }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 0
        configuration.selection = .ordered
        configuration.preferredAssetRepresentationMode = .current
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ view: PHPickerViewController, context: Context) { }

    @MainActor
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        private var results: [PHPickerResult] = []
        init(parent: ImagePicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.picker = false
            guard !results.isEmpty else { return }
            self.results = results
            let generation = parent.samples.beginImport(total: results.count)
            load(results, at: 0, failed: 0, generation: generation)
        }

        private func load(_ results: [PHPickerResult], at index: Int, failed: Int, generation: Int) {
            guard parent.samples.isImporting, parent.samples.importGeneration == generation else { return }
            guard index < results.count else { return }
            let result = results[index]
            let provider = result.itemProvider
            guard let type = provider.registeredTypeIdentifiers.first(where: { UTType($0)?.conforms(to: .image) == true }) else {
                finish(results, at: index, sample: nil, failed: failed, generation: generation)
                return
            }
            var fallbackDate = Date()
            var fallbackLocation: String?
            let authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            if (authorization == .authorized || authorization == .limited), let id = result.assetIdentifier,
               let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject {
                fallbackDate = asset.creationDate ?? fallbackDate
                if let coordinate = asset.location?.coordinate { fallbackLocation = "\(coordinate.latitude),\(coordinate.longitude)" }
            }
            let date = fallbackDate
            let location = fallbackLocation
            let progress = provider.loadDataRepresentation(forTypeIdentifier: type) { data, _ in
                let imported = data.flatMap { SampleImageReader.read($0, fallbackDate: date) }
                let sample = imported.map {
                    ImportedSample(image: $0.image, location: $0.location == "0,0" ? location ?? $0.location : $0.location, date: $0.date)
                }
                DispatchQueue.main.async {
                    self.finish(self.results, at: index, sample: sample, failed: failed, generation: generation)
                }
            }
            parent.samples.trackImport(progress, generation: generation)
        }

        private func finish(_ results: [PHPickerResult], at index: Int, sample: ImportedSample?, failed: Int, generation: Int) {
            guard parent.samples.isImporting, parent.samples.importGeneration == generation else { return }
            if let sample = sample { parent.samples.add(image: sample.image, location: sample.location, times: sample.date) }
            let failures = failed + (sample == nil ? 1 : 0)
            parent.samples.updateImport(completed: index + 1, total: results.count, generation: generation)
            if index + 1 < results.count { load(results, at: index + 1, failed: failures, generation: generation) }
            else if failures > 0 {
                parent.onImportError("\(results.count - failures) of \(results.count) images imported. Some images could not be read or downloaded from iCloud. Choose those images again to retry.")
            }
        }
    }
}
