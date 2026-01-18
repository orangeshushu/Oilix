//
//  LocationEditView.swift
//  Oilix
//
//  Created by Guo, Congyu on 11/21/22.
//

import SwiftUI
import MapKit

struct LocationEditView: View {
    @Binding var ent : Bool
    //@Binding var region:MKCoordinateRegion
    @StateObject var samples : WaterSampleViewModel
    @Binding var ind : Int
    //let dateFormatter = DateFormatter()
    //let geocoder=CLGeocoder()
    //@State var city=""
    @Binding var region : MKCoordinateRegion/* = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude:10,//38.952,
            longitude:10//-92.329
        ),
        span:MKCoordinateSpan(
            latitudeDelta:0.2,
            longitudeDelta:0.2
        )
    )*/
    @State var lat_text : String="0.0"
    @State var lon_text : String="0.0"
    @State private var locAlert=false
    @State private var havenotappear=true
    
    @StateObject var locationManager = LocationManager()
    
    var userLatitude: String {
        return "\(locationManager.lastLocation?.coordinate.latitude ?? 0)"
    }
    
    var userLongitude: String {
        return "\(locationManager.lastLocation?.coordinate.longitude ?? 0)"
    }
    
    var body: some View {
        
        NavigationView{
            GeometryReader{geometry in
                HStack{
                    Spacer()
                    VStack{
                        Spacer()
                        
                        Form{
                            //Section(header:Text("Location")){
                            Section(){
                            /*
                                Text(ind>=0 ? samples.samples[ind].location : "-")//prevent preview from crash
                                                              */
                                ZStack{
                                    //Image(systemName: <#T##String#>)
                                    
                                    //let locs=[entry]
                                    //if(entry.locat?.longitude != 0 || entry.locat?.latitude != 0)
                                    //{
                                    //Map(coordinateRegion: $region,annotationItems: locs, annotationContent: { lo in
                                    Map(coordinateRegion: $region)
                                        .cornerRadius(15)
                                        .frame(width:geometry.size.width*0.8, height:geometry.size.width*0.8)
                                    //.padding()
                                        .allowsHitTesting(false)//so user cannot interact with the map
                                    /*
                                    .onAppear {
                                        print("LEV appear")
                                        if(false){//ind<samples.samples.count){
                                            region.center=History.getLocation(locStr: samples.samples[ind].location) ?? CLLocationCoordinate2D(
                                                latitude:0,
                                                longitude:0
                                                )
                                            /*
                                            region = MKCoordinateRegion(
                                                center: History.getLocation(locStr: samples.samples[ind].location)!,
                                                span:MKCoordinateSpan(
                                                    latitudeDelta:0.2,
                                                    longitudeDelta:0.2
                                                )
                                             */
                                            
                                        }else{//just for preview
                                            
                                        print(region.center.latitude)
                                            region.center=CLLocationCoordinate2D(
                                                latitude:0,
                                                longitude:0
                                                )
                                            print(region.center.latitude)
                                            /*
                                            region = MKCoordinateRegion(
                                                center: CLLocationCoordinate2D(
                                                    latitude:0,
                                                    longitude:0
                                                ),
                                                span:MKCoordinateSpan(
                                                    latitudeDelta:0.2,
                                                    longitudeDelta:0.2
                                                )
                                             */
                                            
                                             
                                        }
                                        
                                    }*/
                                    //}
                                    //Text(entry.locat?.longitude.description ?? "nil")
                                    //Text(city)
                                    PinView(res: "")
                                }
                            }
                            Section(header:Text("latitude")){/*
                                                              Button {
                                                              samples.samples[ind].location = "\(userLatitude),\(userLongitude)"
                                                              region.center=History.getLocation(locStr: samples.samples[ind].location) ?? CLLocationCoordinate2D(
                                                              latitude:0,
                                                              longitude:0
                                                              )
                                                              } label: {
                                                              Text("Overwrite with current location")
                                                              }*/
                                TextField("latitude", text:$lat_text)
                                    .disableAutocorrection(true)
                            }
                            Section(header:Text("longtitude")){
                                TextField("longtitude", text:$lon_text)
                                    .disableAutocorrection(true)
                            }
                            Section(){
                                Button {
                                    //samples.samples[ind].location = "\(userLatitude),\(userLongitude)"
                                    lat_text=userLatitude
                                    lon_text=userLongitude
                                    region.center = CLLocationCoordinate2D(
                                        latitude:Double(lat_text) ?? 0,
                                        longitude:Double(lon_text) ?? 0
                                        )
                                } label: {
                                    Text("Use current location")
                                }
                                .onAppear(){
                                    guard havenotappear else{//prevent value change during swiping
                                        return
                                    }
                                    havenotappear=false
                                    guard ind>=0 else{
                                        print("g1")
                                        return
                                    }
                                    guard samples.samples[ind].location.filter{$0==","}.count == 1 else{
                                        print("g2")
                                        return
                                    }
                                    print("appear!")
                                    let loc=samples.samples[ind].location.split(separator: ",",maxSplits: 1,omittingEmptySubsequences: false)
                                    guard loc.count == 2 else{
                                        print("g3")
                                        return
                                    }
                                    lat_text=String(loc[0])
                                    lon_text=String(loc[1])
                                }
                                /*
                                Button {
                                    
                                print(region.center.latitude)
                                    region.center.latitude+=1
                                    
                                print(region.center.latitude)
                                } label: {
                                    Text("test")
                                }
                                Button {
                                    region.center=CLLocationCoordinate2D(
                                        latitude:0,
                                        longitude:0
                                        )
                                } label: {
                                    Text("test2")
                                }*/
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
            .background(lGray1)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel"){
                        ent=false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save"){
                        guard let lat=Double(lat_text), let lon=Double(lon_text) else{
                            print("not number")
                            locAlert=true
                            return
                        }
                        guard (-180...180).contains(lon), (-90...90).contains(lat) else{
                            print("out of range")
                            locAlert=true
                            return
                        }
                        samples.samples[ind].location = "\(lat_text),\(lon_text)"
                        ent=false
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Detail")
                        .bold()
                }
            })
            
            .alert(isPresented: $locAlert) {
                Alert(title: Text("Error"), message: Text("Invalid input"), dismissButton: .default(Text("dismiss")))
            }
        }
    }
}

struct LocationEditView_Previews: PreviewProvider {
    //@StateObject private var samples = WaterSampleViewModel()
    @State static var ent=true
    @State static var ind = -1
    @State static var region : MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude:10,//38.952,
            longitude:10//-92.329
        ),
        span:MKCoordinateSpan(
            latitudeDelta:0.2,
            longitudeDelta:0.2
        )
        )
    static var previews: some View {
        let samples = WaterSampleViewModel()
        LocationEditView(ent: $ent, samples: samples, ind: $ind, region: $region)
    }
}

