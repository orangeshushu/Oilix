import SwiftUI

enum OilixTourStep: Int, CaseIterable {
    case images, camera, history, profile, instructions

    var tab: Int {
        switch self {
        case .images, .camera: return 2
        case .history: return 1
        case .profile: return 3
        case .instructions: return 4
        }
    }

    var title: String {
        switch self {
        case .images: return "Start with a sample image"
        case .camera: return "Capture a new sample"
        case .history: return "Find your uploaded samples"
        case .profile: return "Keep your profile together"
        case .instructions: return "Help is always here"
        }
    }

    var message: String {
        switch self {
        case .images: return "Choose images from your library or Files. Review the image, notes, and location before uploading. Remove cancels a selection, not the original photo."
        case .camera: return "Tap the large camera button to open Oilix Cam when connected to your sampling camera. Prepare a sample opens the preparation steps."
        case .history: return "History keeps uploaded samples newest first. Search notes or tags, or switch between List and Map."
        case .profile: return "Expand Personal Profile to view your name and email, then open Edit Profile to make changes. Preferences are grouped separately."
        case .instructions: return "Instructions contains preparation, image analysis, and database guides. You can replay this tour here at any time."
        }
    }
}

final class OilixTour: ObservableObject {
    static let completionKey = "oilix.firstUseGuide.completed"
    @Published private(set) var step: OilixTourStep?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func startIfNeeded() {
        guard step == nil, !defaults.bool(forKey: Self.completionKey) else { return }
        step = .images
    }

    func replay() { step = .images }

    func next() {
        guard let step = step else { return }
        if let next = OilixTourStep(rawValue: step.rawValue + 1) { self.step = next }
        else { finish() }
    }

    func back() {
        guard let step = step, let previous = OilixTourStep(rawValue: step.rawValue - 1) else { return }
        self.step = previous
    }

    func finish() {
        defaults.set(true, forKey: Self.completionKey)
        step = nil
    }
}

private struct TourEnvironmentKey: EnvironmentKey {
    static let defaultValue: OilixTour? = nil
}

extension EnvironmentValues {
    var oilixTour: OilixTour? {
        get { self[TourEnvironmentKey.self] }
        set { self[TourEnvironmentKey.self] = newValue }
    }
}

private struct TourTargets: PreferenceKey {
    static var defaultValue: [OilixTourStep: Anchor<CGRect>] = [:]
    static func reduce(value: inout [OilixTourStep: Anchor<CGRect>], nextValue: () -> [OilixTourStep: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    func oilixTourTarget(_ step: OilixTourStep, enabled: Bool = true) -> some View {
        anchorPreference(key: TourTargets.self, value: .bounds) { enabled ? [step: $0] : [:] }
    }

    func oilixTourSurface(tab: Int) -> some View { modifier(TourSurface(tab: tab)) }
}

private struct TourSurface: ViewModifier {
    let tab: Int
    @Environment(\.oilixTour) private var tour

    @ViewBuilder func body(content: Content) -> some View {
        if let tour = tour { GuidedSurface(content: content, tour: tour, tab: tab) }
        else { content }
    }
}

private struct GuidedSurface<Content: View>: View {
    let content: Content
    @ObservedObject var tour: OilixTour
    let tab: Int

    var body: some View {
        let active = tour.step?.tab == tab
        content
            .allowsHitTesting(!active)
            .accessibilityHidden(active)
            .overlayPreferenceValue(TourTargets.self) { targets in
                if let step = tour.step, step.tab == tab {
                    GeometryReader { geometry in
                        TourSpotlight(tour: tour, step: step,
                                      target: targets[step].map { geometry[$0] }, size: geometry.size)
                    }
                }
            }
    }
}

private struct TourSpotlight: View {
    @ObservedObject var tour: OilixTour
    let step: OilixTourStep
    let target: CGRect?
    let size: CGSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @AccessibilityFocusState private var titleFocused: Bool

    // Offscreen targets are not outlined; the guide remains usable without moving drafts or opening pickers.
    private var visibleTarget: CGRect? {
        guard let target = target else { return nil }
        let clipped = target.insetBy(dx: -4, dy: -4).intersection(CGRect(origin: .zero, size: size))
        return clipped.isNull || clipped.height < 24 || clipped.width < 24 ? nil : clipped
    }

    private var cardAtTop: Bool { (visibleTarget?.midY ?? 0) > size.height / 2 }
    private var compact: Bool { size.height < 400 || typeSize.isAccessibilitySize }

    var body: some View {
        ZStack {
            Path { path in
                path.addRect(CGRect(origin: .zero, size: size))
                if !compact, let target = visibleTarget {
                    path.addRoundedRect(in: target, cornerSize: CGSize(width: 8, height: 8))
                }
            }.fill(Color.black.opacity(0.65), style: FillStyle(eoFill: true))
                .accessibilityHidden(true)
            if !compact, let target = visibleTarget {
                Button { advance() } label: {
                    RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 3)
                        .background(Color.white.opacity(0.08))
                }
                .frame(width: target.width, height: target.height)
                .position(x: target.midX, y: target.midY)
                .accessibilityLabel("Continue: \(step.title)")
                .accessibilityIdentifier("tour.highlight")
            }
            VStack(spacing: 0) {
                if !cardAtTop && !compact { Spacer(minLength: 12) }
                guideCard
                    .frame(maxWidth: 480)
                    .padding(16)
                if cardAtTop && !compact { Spacer(minLength: 12) }
            }
        }
        .accessibilityAddTraits(.isModal)
        .onAppear { titleFocused = true }
        .onChange(of: step) { _ in titleFocused = true }
    }

    private var guideCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(step.rawValue + 1) of \(OilixTourStep.allCases.count)").font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Button("Skip") { tour.finish() }.frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("tour.skip")
            }
            .dynamicTypeSize(...(size.height < 400 ? DynamicTypeSize.accessibility1 : .accessibility5))
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(step.title).font(.headline).accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($titleFocused).accessibilityIdentifier("tour.title")
                    Text(step.message).font(.body).fixedSize(horizontal: false, vertical: true)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.frame(maxHeight: compact ? .infinity : 150)
            HStack(spacing: 16) {
                if step != .images {
                    Button("Back") { change { tour.back() } }.frame(minHeight: 44)
                        .accessibilityIdentifier("tour.back")
                }
                Button(action: advance) { Text(step == .instructions ? "Get Started" : "Next").frame(maxWidth: .infinity) }
                    .buttonStyle(PrimaryActionStyle()).accessibilityIdentifier("tour.next")
            }
            .dynamicTypeSize(...(size.height < 400 ? DynamicTypeSize.accessibility1 : .accessibility5))
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(maxHeight: compact ? max(0, size.height - 32) : nil)
    }

    private func advance() { change { tour.next() } }
    private func change(_ action: () -> Void) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2), action)
    }
}

struct AcknowledgementsView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        List {
            Section("Acknowledgements") {
                Text("Thank you to the researchers, field sampling teams, and users who contribute feedback to Oilix.")
                    .fixedSize(horizontal: false, vertical: true)
            }
            Section("Project Institutions") {
                institution("University of Missouri", asset: "mu")
                institution("Missouri State University", asset: "msu")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Acknowledgements").navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func institution(_ name: String, asset: String) -> some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 16) {
                institutionLogo(asset)
                Text(name).fixedSize(horizontal: false, vertical: true)
            }.padding(.vertical, 8)
        } else {
            HStack(spacing: 16) {
                institutionLogo(asset)
                Text(name).fixedSize(horizontal: false, vertical: true)
            }.padding(.vertical, 8)
        }
    }

    private func institutionLogo(_ asset: String) -> some View {
        Image(asset).resizable().scaledToFit().frame(width: 56, height: 64)
            .padding(8).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true)
    }
}
