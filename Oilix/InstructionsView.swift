import SwiftUI

enum OilixGuideTopic: String, CaseIterable, Identifiable {
    case preparation, analysis, database

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preparation: return "Prepare a sample"
        case .analysis: return "Analyze an image"
        case .database: return "Use the database"
        }
    }

    var symbol: String {
        switch self {
        case .preparation: return "testtube.2"
        case .analysis: return "photo"
        case .database: return "map"
        }
    }

    var summary: String {
        switch self {
        case .preparation: return "Extract the sample and capture a fluorescent image."
        case .analysis: return "Choose images, check their details, and upload for results."
        case .database: return "Review locations and manage records on the website."
        }
    }

    var steps: [String] {
        switch self {
        case .preparation:
            return [
                "Collect a 10 ml water sample or a suspected oil wipe directly in a 20 ml vial.",
                "Add 10 ml of hexane and shake the mixture for 30 seconds.",
                "Allow the sample to settle for 1 minute.",
                "If suspended particles remain, add 1 scoop (roughly 0.2 g) of sodium sulfate, shake again, and let it settle for 1 minute.",
                "Pipet approximately 2 ml of the hexane into a cuvette.",
                "Cap the cuvette and confirm the outside surface is free of smudges or particles.",
                "Use the fluorescent image device to capture an image of the sample.",
                "Transfer the image to your phone or computer for analysis.",
            ]
        case .analysis:
            return [
                "Open Oilix and sign in or create an account.",
                "Open Sampling and tap Choose Images to select the image or images to upload. You can also choose from Files or capture with Oilix Cam.",
                "Check each image's details. Edit notes, update the GPS location, or remove incorrect images before uploading.",
                "Tap Upload to send the images and view the prediction results.",
                "Open History to review past uploads, including sample notes, upload dates, and prediction results.",
            ]
        case .database:
            return [
                "Open wateroil.web.app in a web browser and sign in with your Oilix account credentials.",
                "Use Map View to explore uploaded image locations via map markers.",
                "Open List or Database View to browse records and filter by date ranges, tags, or notes.",
                "Select a record to view its image on the map, edit notes and tags, or permanently delete the photo.",
            ]
        }
    }
}

struct InstructionsView: View {
    var isPresentedAsTab = false
    var onOpenSampling: (() -> Void)? = nil
    var onOpenHistory: (() -> Void)? = nil
    var onReplayTour: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .title2) private var iconWidth: CGFloat = 32

    var body: some View {
        OilixNavigation {
            List {
                if let onReplayTour = onReplayTour {
                    Section {
                        Button(action: onReplayTour) {
                            Label("Replay App Tour", systemImage: "sparkles").frame(minHeight: 44)
                        }
                        .accessibilityIdentifier("instructions.replayTour")
                        .oilixTourTarget(.instructions)
                    }
                }
                Section("Guides") {
                    ForEach(OilixGuideTopic.allCases) { topic in
                        NavigationLink(
                            destination: InstructionDetailView(
                                topic: topic,
                                onDone: isPresentedAsTab ? nil : { dismiss() },
                                onOpenSampling: onOpenSampling, onOpenHistory: onOpenHistory)
                        ) {
                            HStack(spacing: 16) {
                                Image(systemName: topic.symbol)
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                    .frame(width: iconWidth)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(topic.title).font(.headline)
                                    Text("\(topic.steps.count) steps")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .accessibilityIdentifier("instructions.\(topic.rawValue)")
                    }
                }
                if onOpenSampling != nil || onOpenHistory != nil {
                    Section("Quick Access") {
                        if let onOpenSampling = onOpenSampling {
                            Button(action: onOpenSampling) {
                                Label("Open Sampling", systemImage: "camera").frame(minHeight: 44)
                            }.accessibilityIdentifier("instructions.openSampling")
                        }
                        if let onOpenHistory = onOpenHistory {
                            Button(action: onOpenHistory) {
                                Label("View Upload History", systemImage: "photo.on.rectangle").frame(minHeight: 44)
                            }.accessibilityIdentifier("instructions.openHistory")
                        }
                    }
                }
                Section {
                    DisclosureGroup("About Oilix") {
                        Text(
                            "Oilix brings field sample images, locations, notes, and analysis results together. The iPhone app supports sampling and upload history; the web database supports reviewing and managing sample records."
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("instructions.introduction")
                    }
                    NavigationLink(destination: AcknowledgementsView()) {
                        Label("Acknowledgements", systemImage: "heart").frame(minHeight: 44)
                    }.accessibilityIdentifier("instructions.acknowledgements")
                    Link(destination: URL(string: "https://wateroil.web.app")!) {
                        Label("Open Web Database", systemImage: "arrow.up.right.square")
                            .frame(minHeight: 44)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if !isPresentedAsTab {
                        Button("Done") { dismiss() }
                            .accessibilityIdentifier("instructions.done")
                    }
                }
            }
        }
        .oilixTourSurface(tab: isPresentedAsTab ? 4 : 0)
    }
}

struct InstructionDetailView: View {
    let topic: OilixGuideTopic
    var onDone: (() -> Void)? = nil
    var onOpenSampling: (() -> Void)? = nil
    var onOpenHistory: (() -> Void)? = nil
    @State private var showAllSteps = false
    @State private var currentStep = 0
    @AccessibilityFocusState private var stepFocused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Picker("Reading mode", selection: $showAllSteps) {
                        Text("Step by Step").tag(false)
                        Text("All Steps").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("instructions.readingMode")
                    .id("guideTop")
                    if showAllSteps {
                        Text(topic.summary).foregroundColor(.secondary)
                        ForEach(Array(topic.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 16) {
                                Text("\(index + 1)")
                                    .font(.headline.monospacedDigit())
                                    .foregroundColor(.accentColor)
                                    .frame(minWidth: 28, alignment: .leading)
                                    .accessibilityHidden(true)
                                Text(step)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Step \(index + 1). \(step)")
                            if index < topic.steps.count - 1 { Divider() }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Step \(currentStep + 1) of \(topic.steps.count)")
                                .font(.headline.monospacedDigit())
                                .accessibilityIdentifier("instructions.stepCount")
                            ProgressView(value: Double(currentStep + 1), total: Double(topic.steps.count))
                                .accessibilityHidden(true)
                            Text(topic.steps[currentStep])
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityFocused($stepFocused)
                                .accessibilityIdentifier("instructions.currentStep")
                        }
                    }
                    if showAllSteps || currentStep == topic.steps.count - 1 { shortcuts }
                }
                .padding(24)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !showAllSteps {
                    VStack(spacing: 0) {
                        Divider()
                        stepControls.padding(.horizontal, 24).padding(.vertical, 8)
                    }.background(.regularMaterial)
                }
            }
            .onChange(of: currentStep) { _ in
                proxy.scrollTo("guideTop", anchor: .top)
                stepFocused = true
            }
            .onChange(of: showAllSteps) { _ in proxy.scrollTo("guideTop", anchor: .top) }
        }
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if let onDone = onDone {
                    Button("Done", action: onDone)
                }
            }
        }
    }

    private var stepControls: some View {
        HStack(spacing: 16) {
            Button {
                currentStep -= 1
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    if !typeSize.isAccessibilitySize { Text("Previous") }
                }.frame(maxWidth: .infinity, minHeight: 44)
            }
            .disabled(currentStep == 0)
            .accessibilityLabel("Previous step")
            .accessibilityIdentifier("instructions.previousStep")
            Button {
                currentStep += 1
            } label: {
                HStack {
                    if !typeSize.isAccessibilitySize { Text("Next") }
                    Image(systemName: "chevron.right")
                }.frame(maxWidth: .infinity, minHeight: 44)
            }
            .disabled(currentStep == topic.steps.count - 1)
            .accessibilityLabel("Next step")
            .accessibilityIdentifier("instructions.nextStep")
        }
        .font(typeSize.isAccessibilitySize ? .system(size: 20, weight: .semibold) : .body)
        .buttonStyle(.bordered)
    }

    @ViewBuilder
    private var shortcuts: some View {
        if topic == .database {
            Link(destination: URL(string: "https://wateroil.web.app")!) {
                Label("Open Web Database", systemImage: "arrow.up.right.square")
                    .frame(minHeight: 44)
            }
        } else {
            if let onOpenSampling = onOpenSampling {
                Button(action: onOpenSampling) {
                    Label("Open Sampling", systemImage: "camera")
                }
                .buttonStyle(PrimaryActionStyle())
                .accessibilityIdentifier("instructions.detail.openSampling")
            }
            if topic == .analysis, let onOpenHistory = onOpenHistory {
                Button(action: onOpenHistory) {
                    Label("View Upload History", systemImage: "photo.on.rectangle")
                        .frame(minHeight: 44)
                }.accessibilityIdentifier("instructions.detail.openHistory")
            }
        }
    }
}
