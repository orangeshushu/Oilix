//
//  HomeView.swift
//  Oilix
//
//  Created by Guo, Congyu on 12/6/21.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack{
            Text("Welcome to Oilix!")
                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
            HStack{
                VStack{
                    Image(systemName: "sunrise")
                        .resizable()
                        .foregroundColor(lGrey2)
                        .frame(width:150,height: 120)
                    
                    Image(systemName: "photo")
                        .resizable()
                        .foregroundColor(lGrey2)
                        .frame(width:150,height: 120)
                     
                    //AsyncImage(url: URL(string:"https://iosacademy.io/assets/images/brand/icon.jpg"))
                    //AsyncImage(url: URL(string:"http://192.168.2.8:8888/out.jpg"))
                        //.frame(width:150,height: 120)
                }
                Image(systemName: "rectangle.portrait")
                    .resizable()
                    .foregroundColor(lGrey2)
                    .frame(width:150,height: 240)
            }
            Image(systemName: "ruler.fill")
                .resizable()
                .foregroundColor(lGrey2)
                .frame(width:300,height: 120)
            HStack{
                Image(systemName: "folder.fill")
                    .resizable()
                    .foregroundColor(lGrey2)
                    .frame(width:150,height: 120)
                Image(systemName: "photo")
                    .resizable()
                    .foregroundColor(lGrey2)
                    .frame(width:150,height: 120)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
