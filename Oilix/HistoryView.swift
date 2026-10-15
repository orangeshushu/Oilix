import SwiftUI
import MapKit

struct HistoryView: View {
    @ObservedObject var se: Session
    @ObservedObject var hist: History
    @StateObject private var locationManager = LocationManager(startImmediately: false)
    @Environment(\.scenePhase) private var scenePhase
    @State private var locationAlert = false
    @State private var mode = 1
    @State private var search = ""
    @FocusState private var searchFocused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var ent = false
    @State private var instructions = false
    @State private var centeredOnUserLocation = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.952, longitude: -92.329),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    @State private var detailRegion = MKCoordinateRegion()
    @State private var itemEnt = sampleHist(date: Date(), locat: nil, result: "", notes: "",
                                           disperseX: 0, disperseY: 0, path: "", tags: "")

    private var records: [sampleHist] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return hist.data }
        return hist.data.filter {
            $0.notes.localizedCaseInsensitiveContains(query) || $0.tags.localizedCaseInsensitiveContains(query)
                || (hist.scope == .all && ($0.username?.localizedCaseInsensitiveContains(query) ?? false))
        }
    }

    private var mappedRecords: [sampleHist] {
        records.filter {
            guard let location = $0.locat else { return false }
            return location.latitude != 0 || location.longitude != 0
        }
    }

    var body: some View {
        OilixNavigation {
            VStack(spacing: 0) {
                if mode == 2 || (hist.data.isEmpty && (hist.isLoading || hist.errorMessage != nil)) {
                    historyControls
                }
                if let error = hist.errorMessage, !hist.data.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        FormMessage(text: error)
                        Button("Try Again") { hist.getHistory() }.disabled(hist.isLoading)
                    }.padding(.horizontal).padding(.bottom, 12)
                }
                if hist.isLoading && !hist.data.isEmpty { ProgressView("Refreshing History...").padding(.bottom, 12) }
                if hist.isLoading && hist.data.isEmpty {
                    Spacer()
                    ProgressView("Loading History...")
                    Spacer()
                } else if let error = hist.errorMessage, hist.data.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.exclamationmark").font(.title).foregroundColor(.secondary)
                        Text(error).multilineTextAlignment(.center)
                        Button("Try Again") { hist.getHistory() }.frame(minHeight: 44)
                    }.padding(24)
                    Spacer()
                } else if mode == 1 {
                    historyList
                } else {
                    mapView
                }
            }
            .oilixKeyboardDismissal()
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { instructions = true } label: {
                        Image(systemName: "book").font(.system(size: 18))
                    }
                    .accessibilityLabel("Instructions")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { hist.getHistory() } label: {
                        Image(systemName: "arrow.clockwise").font(.system(size: 18))
                    }.disabled(hist.isLoading).accessibilityLabel("Refresh history")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { searchFocused = false }
                }
            }
        }
        .oilixTourSurface(tab: 1)
        .onAppear {
            hist.getHistory()
            if mode == 2 { locationManager.start() }
        }
        .onChange(of: mode) { mode in
            searchFocused = false
            if mode == 2 { locationManager.start(); centerOnCurrentLocation() }
            else { locationManager.stop() }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active && mode == 2 { locationManager.start() }
            else { locationManager.stop() }
        }
        .onDisappear { locationManager.stop() }
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { location in
            guard mode == 2, scenePhase == .active, locationManager.hasAccess,
                  LocationManager.isUsable(location), !centeredOnUserLocation else { return }
            region.center = location.coordinate
            centeredOnUserLocation = true
        }
        .sheet(isPresented: $ent) { EntryView(ent: $ent, region: $detailRegion, entry: $itemEnt) }
        .sheet(isPresented: $instructions) { InstructionsView() }
        .alert("Location Unavailable", isPresented: $locationAlert) {
            if locationManager.locationStatus == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
            }
            Button("OK", role: .cancel) { }
        } message: { Text(locationManager.statusString) }
    }

    private var historyControls: some View {
        VStack(spacing: 8) {
            if typeSize.isAccessibilitySize {
                if hist.canViewAllSamples { scopeMenu.frame(maxWidth: .infinity, alignment: .leading) }
                viewPicker
            } else {
                HStack(spacing: 16) {
                    if hist.canViewAllSamples {
                        scopeMenu
                        Spacer(minLength: 0)
                    }
                    viewPicker.frame(maxWidth: hist.canViewAllSamples ? 140 : .infinity)
                }
            }
            searchField.oilixTourTarget(.history)
            Group {
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 4) {
                        sampleCount
                        Text("Newest first")
                    }.frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack {
                        sampleCount
                        Spacer(minLength: 8)
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down").font(.system(size: 10, weight: .medium))
                            Text("Newest first")
                        }
                    }
                }
            }
            .font(.caption).foregroundColor(.secondary)
            .padding(.top, 4)
        }
        .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 12)
        .background(Color(uiColor: .systemBackground))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(uiColor: .separator)).frame(height: 0.5)
        }
    }

    private var sampleCount: some View {
        Text("\(records.count) samples")
            .accessibilityIdentifier("history.count")
            .opacity(hist.isLoading ? 0 : 1)
    }

    private var scopeMenu: some View {
        Menu {
            Picker("Samples", selection: Binding(get: { hist.scope }, set: { hist.selectScope($0) })) {
                ForEach(HistoryScope.allCases, id: \.self) { scope in Text(scope.title).tag(scope) }
            }
        } label: {
            HStack(spacing: 6) {
                Text(hist.scope.title).font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold))
            }.frame(minHeight: 44)
        }
        .disabled(hist.isLoading)
        .accessibilityIdentifier("history.scope")
    }

    private var viewPicker: some View {
        HStack(spacing: 4) {
            viewButton("List", symbol: "list.bullet", value: 1)
            viewButton("Map", symbol: "map", value: 2)
        }
        .padding(3).background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("History view")
    }

    private func viewButton(_ title: String, symbol: String, value: Int) -> some View {
        Button { mode = value } label: {
            Image(systemName: symbol).font(.system(size: 18, weight: .medium))
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundColor(mode == value ? .accentColor : .secondary)
                .background(mode == value ? Color(uiColor: .systemBackground) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain).accessibilityLabel(title)
        .accessibilityAddTraits(mode == value ? .isSelected : [])
        .accessibilityIdentifier("history.view.\(value)")
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 16)).foregroundColor(.secondary)
            TextField("Search samples", text: $search)
                .textFieldStyle(.plain).submitLabel(.search)
                .focused($searchFocused).onSubmit { searchFocused = false }
                .accessibilityLabel("Search history").accessibilityIdentifier("history.search")
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 16))
                        .foregroundColor(.secondary).frame(width: 44, height: 44)
                }.buttonStyle(.plain).accessibilityLabel("Clear search")
                    .accessibilityIdentifier("history.clearSearch")
            }
        }.padding(.leading, 12).padding(.trailing, search.isEmpty ? 12 : 0)
            .frame(minHeight: 44).background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var historyList: some View {
        List {
            historyControls
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            if records.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(search.isEmpty ? "No uploads yet" : "No matching samples").font(.headline)
                    Text(search.isEmpty ? (hist.scope == .all ? "No samples have been uploaded." : "Your uploaded samples will appear here.") : "Try a different search.")
                        .foregroundColor(.secondary)
                }.padding(.vertical, 16)
            } else {
                ForEach(records) { item in
                    Button { open(item) } label: {
                        HStack(alignment: .center, spacing: 12) {
                            AsyncImage(url: imageURL(for: item.path)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                case .failure:
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Color(uiColor: .secondarySystemBackground))
                                case .empty:
                                    ProgressView()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Color(uiColor: .secondarySystemBackground))
                                @unknown default:
                                    Color(uiColor: .secondarySystemBackground)
                                }
                            }
                            .frame(width: 76, height: 76)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.displayTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                                (Text(item.result.isEmpty ? "Result not available" : item.result)
                                    .font(.headline).foregroundColor(.primary)
                                 + Text(item.result.isEmpty ? "" : " mg/L")
                                    .font(.caption).foregroundColor(.secondary))
                                    .monospacedDigit()
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(recordMetadata(item))
                                    .font(.caption).foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                if !item.tags.isEmpty {
                                    Text(item.tags).font(.caption).foregroundColor(.accentColor)
                                        .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                                }
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                                .accessibilityHidden(true)
                        }.padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("history.record.\(item.id)")
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                }
            }
        }
        .id(hist.scope)
        .listStyle(.plain)
        .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 16) }
        .oilixKeyboardDismissal()
        .refreshable {
            await withCheckedContinuation { continuation in
                hist.getHistory { continuation.resume() }
            }
        }
    }

    private func recordMetadata(_ item: sampleHist) -> String {
        let date = item.date.formatted(date: .abbreviated, time: .omitted)
        guard hist.scope == .all, let username = item.username, !username.isEmpty else { return date }
        if typeSize.isAccessibilitySize { return "\(date)\n\(username)" }
        return "\(date) \u{00B7} \(username)"
    }

    private var mapView: some View {
        Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: mappedRecords) { item in
            MapAnnotation(coordinate: pinLocation(for: item)) {
                Button { open(item) } label: { PinView(res: item.result) }
                    .accessibilityLabel(item.notes.isEmpty ? "Sample location" : item.notes)
                    .accessibilityValue(item.result.isEmpty ? "Result not available" : "\(item.result) mg/L")
            }
        }
        .overlay(alignment: .bottomLeading) {
            Button {
                locationManager.start()
                if locationManager.locationStatus == .denied || locationManager.locationStatus == .restricted {
                    locationAlert = true
                } else { centerOnCurrentLocation() }
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .padding(16)
            .accessibilityLabel("Center on my location")
        }
        .overlay(alignment: .top) {
            if mappedRecords.isEmpty {
                Label("No samples with GPS data", systemImage: "location.slash")
                    .font(.subheadline).padding().frame(maxWidth: .infinity).background(.regularMaterial)
            }
        }
    }

    private func pinLocation(for item: sampleHist) -> CLLocationCoordinate2D {
        let location = item.locat!
        let shifted = CLLocationCoordinate2D(latitude: location.latitude + (se.disperse ? item.disperseX : 0),
                                             longitude: location.longitude + (se.disperse ? item.disperseY : 0))
        return CLLocationCoordinate2DIsValid(shifted) ? shifted : location
    }

    private func open(_ item: sampleHist) {
        detailRegion = MKCoordinateRegion(center: item.locat ?? region.center,
                                          span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        itemEnt = item
        ent = true
    }

    private func imageURL(for path: String) -> URL? {
        path.hasPrefix("http://") || path.hasPrefix("https://") ? URL(string: path) : URL(string: serverURL + path)
    }

    private func centerOnCurrentLocation() {
        guard locationManager.hasAccess, let location = locationManager.lastLocation, LocationManager.isUsable(location) else { return }
        region.center = location.coordinate
        centeredOnUserLocation = true
    }
}
