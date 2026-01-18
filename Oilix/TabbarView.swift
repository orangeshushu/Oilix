//
//  TabbarView.swift
//  Oilix
//
//  Created by Guo, Congyu on 12/6/21.
//

import SwiftUI

struct TabbarView: View {
    @StateObject var se:Session
    @State private var selection=2
    var body: some View {
        TabView(selection: $selection){
            /*
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
             */
            HistoryView(se:se)
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("History")
                }
                .tag(1)
            SamplingView(se: se)
                .tabItem {
                    Image(systemName: "camera")
                    Text("Sampling")
                }
                .tag(2)
            /*
            AnalyzingView()
                .tabItem {
                    Image(systemName: "mail.and.text.magnifyingglass")
                    Text("Analyzing")
                }
             */
            SettingView(se: se)
                .tabItem {
                    Image(systemName: "wrench")
                    Text("Settings")
                }
                .tag(3)
        }
    }
}

struct TabbarView_Previews: PreviewProvider {
    static var previews: some View {
        let se=Session()
        TabbarView(se: se)
    }
}
