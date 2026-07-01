//
//  HistoryView.swift
//  Oilix
//
//  Created by Guo, Congyu on 12/31/21.
//

import SwiftUI
import MapKit



/*
struct History{
    
    var data = [sampleHist]()
    //var data = [sampleHist(date:Date(timeIntervalSince1970: -1368835200),latitude:32,longitude:119, result:114.514, locat(latitude))]
    
    //init(){
        //getHistory()
    //}
    
    func getHistory(){
        dummyData(amont: 20)
    }
    
    func dummyData(amont:Int){
        
        //print("dummy data got")
        print(data.count)
    }
}
 */
//let hist = History()

struct HistoryView: View {
    @StateObject var se:Session
    @State var mode=1
    @State var ent=false
    @ObservedObject var hist = History()
    @StateObject var locationManager = LocationManager()
    @State private var centeredOnUserLocation = false
    @State var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude:38.952,
            longitude:-92.329
        ),
        span:MKCoordinateSpan(
            latitudeDelta:0.2,
            longitudeDelta:0.2
        )
    )
    @State var region2 = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude:38.952,
            longitude:-92.329
        ),
        span:MKCoordinateSpan(
            latitudeDelta:0.2,
            longitudeDelta:0.2
        )
    )
    @State var itemEnt = sampleHist(date: Date(timeIntervalSince1970: 0), locat: CLLocationCoordinate2D(), result: "", notes: "", disperseX: 0, disperseY: 0, path: "", tags: "")
    let dateFormatter = DateFormatter()
    //let hd:History
    //@State var hd=[sampleHist]()
    var body: some View {
        VStack{
            Text(se.name+"'s upload history")
            Picker("Mode",selection: $mode) {
                Text("list").tag(1)
                Text("map").tag(2)
            }.pickerStyle(SegmentedPickerStyle())
            
            
            if(mode==1)
            {
                NavigationView{
                    //List(0..<15){item in
                    List(hist.data, id:\.id){item in
                        HStack(spacing: 12){
                            AsyncImage(url: historyImageURL(for: item.path)){phase in
                                switch phase{
                                case .empty:
                                    ZStack{
                                        Rectangle()
                                            .fill(lGrey2)
                                        ProgressView()
                                    }
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    ZStack{
                                        Rectangle()
                                            .fill(lGrey2)
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading, spacing: 6){
                                HStack{
                                    Image(systemName: "note.text")
                                    Text(":")
                                    Text("\(item.notes)")
                                        .lineLimit(2)
                                }
                                Spacer(minLength: 0)
                            }
                            Spacer()
                            VStack(alignment: .leading, spacing: 6){
                                //NavigationLink(destination: EntryView(ent:$ent,region: $region, entry:item)) {
                                    //Text(item.id.uuidString)
                                    Text(dateFormatter.string(from:item.date))
                                    if(item.result == ""){
                                        Text("Result not available")
                                    }
                                    else{
                                        HStack{
                                            Image(systemName: "testtube.2")
                                            Text(": \(item.result)")
                                        }
                                    }
                                //}
                                
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            region.center.latitude=item.locat?.latitude ?? 0
                            region.center.longitude=item.locat?.longitude ?? 0
                            region.span=MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
                            print("mode 1 longitude \(region.span.longitudeDelta ?? 0)")
                            itemEnt=item
                            ent=true
                        }
                    }
                    .navigationTitle("History")
                }
            }
            if(mode==2)
            {
                Spacer()
                if se.disperse{
                    Map(coordinateRegion:$region2, showsUserLocation: true, annotationItems: hist.data, annotationContent:  { lo in
                        MapAnnotation(coordinate: CLLocationCoordinate2D(latitude:(lo.locat?.latitude ?? 38.912)+lo.disperseX,longitude:(lo.locat?.longitude ?? -92.277)+lo.disperseY)){
                            PinView(res: lo.result)
                                .shadow(radius: 10)
                                .onTapGesture {
                                    region.center.latitude=lo.locat?.latitude ?? 0
                                    region.center.longitude=lo.locat?.longitude ?? 0
                                    region.span=MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
                                    //print("mode 2 longitude \(region.span.longitudeDelta ?? 0)")
                                    itemEnt=lo
                                    ent=true
                                }
                        }
                    })
                }
                else{
                    Map(coordinateRegion:$region2, showsUserLocation: true, annotationItems: hist.data, annotationContent:  { lo in
                        MapAnnotation(coordinate: lo.locat ?? CLLocationCoordinate2D(latitude:38.912,longitude:-92.277)) {
                            PinView(res: lo.result)
                                .shadow(radius: 10)
                                .onTapGesture {
                                    region.center.latitude=lo.locat?.latitude ?? 0
                                    region.center.longitude=lo.locat?.longitude ?? 0
                                    region.span=MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
                                    //print("mode 2 longitude \(region.span.longitudeDelta ?? 0)")
                                    itemEnt=lo
                                    ent=true
                                }
                        }
                    })
                }
                    //.frame(width:300, height:300)
                Spacer()
            }
            
        }
        .onAppear {
            print("history test")
            //dateFormatter.dateFormat = "YYYY/MM/dd"
            dateFormatter.dateFormat = "MM/dd/YYYY"
            
            hist.getHistory()
            centerMapOnCurrentLocationIfNeeded()
        }
        .onChange(of: mode) { newMode in
            if newMode == 2 {
                centerMapOnCurrentLocationIfNeeded()
            }
        }
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { location in
            centerMap(on: location)
        }
        .onDisappear {
            //print("history test2")
        }
        .sheet(isPresented: $ent, content: {
            EntryView(ent:$ent, region: $region, entry:$itemEnt)
        })
    }
    
    private func historyImageURL(for path: String) -> URL? {
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }
        
        return URL(string: serverURL + path)
    }
    
    private func centerMapOnCurrentLocationIfNeeded() {
        guard let location = locationManager.lastLocation else {
            return
        }
        
        centerMap(on: location)
    }
    
    private func centerMap(on location: CLLocation) {
        guard !centeredOnUserLocation else {
            return
        }
        
        region2.center = location.coordinate
        region2.span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        centeredOnUserLocation = true
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let se=Session()
        HistoryView(se:se)
    }
}
