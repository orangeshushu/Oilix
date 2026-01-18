//
//  AlbumView.swift
//  Oilix
//
//  Created by Guo, Congyu on 12/6/21.
//

import SwiftUI

struct AlbumView: View {
    var body: some View {
        ZStack {
            VStack {
                HStack{
                    Image(systemName: "photo")
                        .resizable()
                        .foregroundColor(lGrey2)
                        .frame(width:150,height: 120)
                    Image(systemName: "photo")
                        .resizable()
                        .foregroundColor(lGrey2)
                        .frame(width:150,height: 120)
                }
                HStack{
                    Image(systemName: "photo")
                        .resizable()
                        .foregroundColor(lGrey2)
                        .frame(width:150,height: 120)
                    Image(systemName: "photo")
                        .resizable()
                        .foregroundColor(lGrey2)
                        .frame(width:150,height: 120)
                }
                HStack{
                    Image(systemName: "photo")
                        .resizable()
                        .foregroundColor(lGrey2)
                        .frame(width:150,height: 120)
                    Image(systemName: "photo")
                        .resizable()
                        .foregroundColor(lGrey2)
                        .frame(width:150,height: 120)
                }
                Spacer()
            }
            Text("To be continued")
                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
            //Button(){print("Hello world!")}label:{Image(systemName:"forward.fill")}
        }
    }
}

struct AlbumView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumView()
    }
}
