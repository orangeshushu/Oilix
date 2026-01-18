//
//  EntryView.swift
//  Oilix
//
//  Created by Guo, Congyu on 8/18/22.
//

import SwiftUI
import MapKit

struct EntryView: View {
    @Binding var ent : Bool
    @Binding var region:MKCoordinateRegion
    @Binding var entry : sampleHist
    let dateFormatter = DateFormatter()
    //let geocoder=CLGeocoder()
    //@State var city=""
    var body: some View {
        
        NavigationView{
            GeometryReader{geometry in
                VStack{
                    //Spacer()
                    HStack{
                        Spacer()
                        AsyncImage(url: URL(string: serverURL+entry.path)){phase in
                            switch phase{
                            case .empty:
                                ProgressView()
                                    .frame(width:geometry.size.width*0.8, height:geometry.size.width*0.6)
                                    .padding()
                            case .success(let image):
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(15)
                                    .frame(width:geometry.size.width*0.8, height:geometry.size.width*0.6)
                                    .padding()
                            case .failure:
                                Image(systemName: "xmark.octagon")
                                    .foregroundColor(.gray)
                                    .frame(width:geometry.size.width*0.8, height:geometry.size.width*0.6)
                                    .padding()
                            @unknown default:
                                EmptyView()
                                
                            }
                        }
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(dateFormatter.string(from:entry.date))
                        //.font(.title2)
                        Text("concentration: "+entry.result+"mg/L")
                            .foregroundColor(Color.gray)
                        //Text("note: "+entry.notes)
                    }
                    .frame(width:geometry.size.width*0.8, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(entry.notes)
                            .foregroundColor(Color.gray)
                            .padding(12)
                        if(entry.tags != ""){
                            VStack(alignment: .leading, spacing: 0) {
                                Text(entry.tags)
                                    .cornerRadius(5)
                                    .foregroundColor(Color.white)
                                    .background(lGray4)
                                    .padding(10)
                            }
                            .frame(width:geometry.size.width*0.8, alignment: .leading)
                            .background(lGray3)
                        }
                        //Text("note: "+entry.notes)
                    }
                    .frame(width:geometry.size.width*0.8, alignment: .leading)
                    .background(lGrey2)
                    .cornerRadius(15)
                    
                    let locs=[entry]
                    if(entry.locat?.longitude != 0 || entry.locat?.latitude != 0)
                    {
                        Map(coordinateRegion: $region,annotationItems: locs, annotationContent: { lo in
                            MapAnnotation(coordinate: lo.locat!) {
                                PinView(res: lo.result)
                                    .shadow(radius: 10)
                            }
                        })
                        .cornerRadius(15)
                        .frame(width:geometry.size.width*0.8/*, height:geometry.size.width*0.4*/)
                        .padding()
                        .allowsHitTesting(false)//so user cannot interact with the map
                    }
                    //Text(entry.locat?.longitude.description ?? "nil")
                    //Text(city)
                    Spacer()
                }
            }
            .background(lGray1)
            .toolbar(content: {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done"){
                        ent=false
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Detail")
                        .bold()
                }
            })
            .onAppear {
                //dateFormatter.dateFormat = "YYYY/MM/dd"
                dateFormatter.dateFormat = "EEEE, MMM d, yyyy • h:mm a"
                //print("appear")
                //print("entry longitude \(region.span.longitudeDelta)")
                /*
                 //This code allows app to get the city name with gps coordinates. However, Apple suggest do not send more than one request per minute, so I dropped this function. For more:https://developer.apple.com/documentation/corelocation/clgeocoder
                 let location=CLLocation(latitude: entry.locat?.latitude ?? 0, longitude: entry.locat?.longitude ?? 0)
                 if(location.coordinate.longitude != 0 || location.coordinate.latitude != 0)
                 {
                 geocoder.reverseGeocodeLocation(location) { placemarks, error->Void in
                 if let placemark = placemarks?.first
                 {
                 if(placemark.isoCountryCode != nil)
                 {
                 //city=placemark.description
                 if(placemark.isoCountryCode=="US")
                 {
                 city=(placemark.locality ?? "")+", "+(placemark.administrativeArea ?? "")
                 }
                 else{
                 city=(placemark.administrativeArea ?? "")+", "+(placemark.country ?? "")
                 }
                 print("*******")
                 print(placemark.isoCountryCode)
                 print("*******")
                 }
                 else{
                 city="nil"
                 }
                 }
                 else{
                 city=error.debugDescription
                 }
                 }
                 }
                 */
            }
        }
    }
}

struct EntryView_Previews: PreviewProvider {
    @State static var exent=sampleHist(date: Date(timeIntervalSince1970: 0), locat: History.getLocation(locStr: "38.9242,-92.3362"), result: "114.514", notes: "1919810", disperseX: 0, disperseY: 0, path: "static/images/08A29BCAE467C60E.jpeg", tags: "#dummy")
    @State static var reg=MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 38.9242, longitude: -92.3362), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    @State static var re=true
    static var previews: some View {
        
        EntryView(ent: $re, region: $reg, entry: $exent)
    }
}
