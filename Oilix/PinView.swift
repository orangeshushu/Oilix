//
//  PinView.swift
//  Oilix
//
//  Created by Guo, Congyu on 2/15/22.
//

import SwiftUI
import MapKit

struct PinView: View {
    //@State var lo:CLLocationCoordinate2D
    @State var res:String
    var body: some View {
        VStack{
            ZStack{
                
                Image(systemName: "stop")
                    .resizable()
                //.scaledToFit()
                    .frame(width: 60, height: 30)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .background(.white)
                
                if(res == ""){
                    Text("-")
                }
                else{
                    //Text(String(format: "%.1f", res))
                    Text(res.prefix(5))
                }
                //Image(systemName: "stop.fill")
            }
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.blue)
                .frame(width: 15, height: 15)
                .rotationEffect(Angle(degrees: 180))
                .offset(y:-10)
                .padding(.bottom, 27)
        }
        //.background(.red)
    }
}

struct PinView_Previews: PreviewProvider {
    static var previews: some View {
        //PinView(lo:CLLocationCoordinate2D(latitude:38.952,longitude:-92.329))
        PinView(res:"114.514")
    }
}
