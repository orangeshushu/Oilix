//
//  TabbarView.swift
//  Oilix
//
//  Created by Guo, Congyu on 12/6/21.
//

import SwiftUI

struct TabbarView: View {
    @ObservedObject var se:Session
    @StateObject private var samples = WaterSampleViewModel()
    @StateObject private var upload = SampleUploadController()
    @StateObject private var history: History
    @StateObject private var tour = OilixTour()
    @State private var selection=2
    @State private var tourExitTab: Int?

    init(se: Session) {
        self.se = se
        _history = StateObject(wrappedValue: History(isAdmin: se.isAdmin))
    }

    var body: some View {
        TabView(selection: $selection){
            SamplingView(se: se, tabSelection: $selection, samples: samples, upload: upload)
                .tabItem {
                    Image(systemName: "camera")
                    Text("Sampling")
                }
                .tag(2)
            HistoryView(se: se, hist: history)
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("History")
                }
                .tag(1)
            InstructionsView(isPresentedAsTab: true,
                             onOpenSampling: { selection = 2 },
                             onOpenHistory: { selection = 1 },
                             onReplayTour: { tour.replay() })
                .tabItem {
                    Image(systemName: "book")
                    Text("Instructions")
                }
                .tag(4)
            SettingView(se: se, hasPendingSamples: samples.samples.contains { !$0.online },
                        isSamplingBusy: upload.isBusy || samples.isImporting)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .environment(\.oilixTour, tour)
        .onAppear { tour.startIfNeeded() }
        .onChange(of: tour.step) { step in
            selection = step?.tab ?? tourExitTab ?? 2
            if step == nil { tourExitTab = nil }
        }
        .onChange(of: selection) { tab in
            if let step = tour.step, tab != step.tab {
                tourExitTab = tab
                tour.finish()
            }
        }
    }
}

struct TabbarView_Previews: PreviewProvider {
    static var previews: some View {
        let se=Session()
        TabbarView(se: se)
    }
}
