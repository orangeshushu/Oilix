//
//  ContentView.swift
//  Oilix
//
//  Created by Guo, Congyu on 11/21/21.
//

import SwiftUI

struct ContentView: View {
    @StateObject var se:Session
    var body: some View {
        //Text("Hello, world!")
            //.padding()
        /*
        if !se.isLoggedIn {
            LoginView(se: se)
        } else {
            TabbarView(se: se)
        }
         */
        if se.isLoggedIn {
            TabbarView(se: se)
        } else {
            LoginView(se: se)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let se=Session()
        ContentView(se:se)
    }
}
