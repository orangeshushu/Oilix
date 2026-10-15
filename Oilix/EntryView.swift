import SwiftUI
import MapKit

struct EntryView: View {
    @Binding var ent: Bool
    @Binding var region: MKCoordinateRegion
    @Binding var entry: sampleHist
    @StateObject private var image = SampleImageLoader()
    @State private var expanded = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var coordinate: CLLocationCoordinate2D? {
        guard let value = entry.locat, CLLocationCoordinate2DIsValid(value),
              value.latitude != 0 || value.longitude != 0 else { return nil }
        return value
    }

    var body: some View {
        OilixNavigation {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    photo
                    VStack(alignment: .leading, spacing: 14) {
                        Text(entry.displayTitle).font(.title3.bold())
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        prediction
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 14) {
                        metadata("Uploaded", symbol: "calendar", value: entry.date.formatted(date: .abbreviated, time: .omitted))
                        if let username = entry.username, !username.isEmpty {
                            metadata("Uploaded by", symbol: "person", value: username)
                        }
                    }
                    Divider()
                    textSection("Notes", symbol: "note.text", value: entry.notes.isEmpty ? "No notes added" : entry.notes,
                                isEmpty: entry.notes.isEmpty)
                    if !entry.tags.isEmpty { textSection("Tags", symbol: "tag", value: entry.tags) }
                    Divider()
                    location
                }
                .padding(20).padding(.bottom, 12)
                .frame(maxWidth: 640, alignment: .leading).frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("detail.content")
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Sample Details").navigationBarTitleDisplayMode(.inline)
            .modifier(DetailNavigationBackground())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { ent = false } }
            }
        }
        .onAppear(perform: loadImage)
        .fullScreenCover(isPresented: $expanded) {
            OilixNavigation {
                Group {
                    if let loaded = image.image { SampleImageZoom(image: loaded).ignoresSafeArea(edges: .bottom) }
                }
                .background(Color.black)
                .navigationTitle("Sample Image").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { expanded = false } } }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var photo: some View {
        Color(uiColor: .secondarySystemBackground)
            .frame(height: verticalSizeClass == .compact ? 180 : 240)
            .overlay {
                if let loaded = image.image {
                    Button { expanded = true } label: {
                        Image(uiImage: loaded).resizable().scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(.regularMaterial, in: Circle())
                                    .padding(10).accessibilityHidden(true)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View sample image full screen")
                    .accessibilityIdentifier("detail.image")
                } else if image.loading {
                    ProgressView("Loading Image...")
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo").font(.title2).foregroundColor(.secondary)
                        Text("Image unavailable").font(.subheadline).foregroundColor(.secondary)
                        Button("Try Again", action: loadImage).frame(minHeight: 44)
                    }.padding(12)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var prediction: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("Prediction", systemImage: "testtube.2")
                .font(.subheadline).foregroundColor(.secondary)
            if entry.result.isEmpty {
                Text("Result not available").font(.headline).foregroundColor(.secondary)
            } else {
                (Text(entry.result).font(.largeTitle.weight(.semibold))
                 + Text(" mg/L").font(.title3).foregroundColor(.secondary))
                    .monospacedDigit().fixedSize(horizontal: false, vertical: true)
            }
        }
        .textSelection(.enabled)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("detail.prediction")
    }

    private func metadata(_ title: String, symbol: String, value: String) -> some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    Label(title, systemImage: symbol).foregroundColor(.secondary)
                    Text(value).textSelection(.enabled)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Label(title, systemImage: symbol).foregroundColor(.secondary)
                    Spacer(minLength: 0)
                    Text(value).multilineTextAlignment(.trailing).textSelection(.enabled)
                }
            }
        }
        .font(.subheadline).fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    private func textSection(_ title: String, symbol: String, value: String, isEmpty: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol).font(.subheadline.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Text(value).font(.body).foregroundColor(isEmpty ? .secondary : .primary)
                .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
        }
    }

    private var location: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Location", systemImage: "mappin.and.ellipse")
                .font(.subheadline.weight(.semibold)).accessibilityAddTraits(.isHeader)
            if let coordinate = coordinate {
                Map(coordinateRegion: $region, annotationItems: [entry]) { _ in
                    MapMarker(coordinate: coordinate, tint: .accentColor)
                }
                .frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Sample location")
                Text(String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude))
                    .font(.caption).foregroundColor(.secondary).textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                    item.name = entry.displayTitle
                    item.openInMaps()
                } label: {
                    Label("Open in Maps", systemImage: "arrow.up.right.square")
                        .frame(minHeight: 44)
                }
            } else {
                Text("No GPS data for this sample").font(.subheadline)
                    .foregroundColor(.secondary).accessibilityIdentifier("detail.noLocation")
            }
        }
    }

    private func loadImage() {
        let url = entry.path.hasPrefix("http://") || entry.path.hasPrefix("https://")
            ? URL(string: entry.path) : URL(string: serverURL + entry.path)
        image.load(url)
    }
}

private struct DetailNavigationBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.toolbarBackground(Color(uiColor: .systemBackground), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(colorScheme, for: .navigationBar)
        } else {
            content
        }
    }
}

@MainActor
private final class SampleImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var loading = false
    private var task: URLSessionDataTask?

    func load(_ url: URL?) {
        guard let url = url, !loading, image == nil else { return }
        loading = true
        task = URLSession.shared.dataTask(with: URLRequest(url: url, timeoutInterval: 20)) { [weak self] data, response, error in
            let result: UIImage?
            if error == nil, let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), let data = data {
                result = UIImage(data: data)?.preparingForDisplay()
            } else { result = nil }
            DispatchQueue.main.async { self?.image = result; self?.loading = false; self?.task = nil }
        }
        task?.resume()
    }

    deinit { task?.cancel() }
}

private struct SampleImageZoom: UIViewRepresentable {
    let image: UIImage
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> SampleZoomScrollView {
        let view = SampleZoomScrollView()
        view.minimumZoomScale = 1; view.maximumZoomScale = 4
        view.delegate = context.coordinator
        view.imageView.image = image
        view.backgroundColor = .black
        view.accessibilityLabel = "Sample image"
        view.accessibilityIdentifier = "detail.zoom"
        view.accessibilityValue = "100%"
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTap(_:)))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
        return view
    }
    func updateUIView(_ view: SampleZoomScrollView, context: Context) { view.imageView.image = image }
    final class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { (scrollView as? SampleZoomScrollView)?.imageView }
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            scrollView.accessibilityValue = String(format: "%.0f%%", scrollView.zoomScale * 100)
        }
        @objc func doubleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? SampleZoomScrollView else { return }
            let scale: CGFloat = view.zoomScale > 1 ? 1 : 3
            let point = gesture.location(in: view.imageView)
            let size = CGSize(width: view.bounds.width / scale, height: view.bounds.height / scale)
            view.zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2,
                                 width: size.width, height: size.height), animated: !UIAccessibility.isReduceMotionEnabled)
        }
    }
}

private final class SampleZoomScrollView: UIScrollView {
    let imageView = UIImageView()
    private var lastSize = CGSize.zero
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != lastSize else { return }
        lastSize = bounds.size
        setZoomScale(1, animated: false)
        imageView.frame = CGRect(origin: .zero, size: bounds.size)
        contentSize = bounds.size
    }
}
