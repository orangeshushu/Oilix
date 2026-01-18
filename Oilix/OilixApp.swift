//
//  OilixApp.swift
//  Oilix
//
//  Created by Guo, Congyu on 11/21/21.
//

import SwiftUI

let lGrey=Color(red:239.0/255.0, green:243.0/255.0, blue:244.0/255.0, opacity: 100.0/255.0)
let lGrey2=Color(red:239.0/255.0, green:243.0/255.0, blue:244.0/255.0, opacity: 200.0/255.0)
let lGray1=Color(red:247/255.0, green:247/255.0, blue:249/255.0, opacity: 255/255.0)
let lGray2=Color(red:235/255.0, green:234/255.0, blue:239/255.0, opacity: 255/255.0)
let lGray3=Color(red:221/255.0, green:220/255.0, blue:225/255.0, opacity: 255/255.0)
let lGray4=Color(red:171/255.0, green:170/255.0, blue:175/255.0, opacity: 255/255.0)
let deviceName="Oilix Cam"
let accessPointName="Oilix Cam"
let cameraURL="http://192.168.0.1/"
//let serverURL="https://wateroil.itongue.cn/"
let serverURL="https://wateroil.covlab.tech/"
//let serverURL="https://oilix.covlab.tech:4431/"

@main
struct OilixApp: App {
    let se=Session()
    var body: some Scene {
        WindowGroup {
            ContentView(se: se)
        }
    }
}
