//
//  NoteView.swift
//  Oilix
//
//  Created by Guo, Congyu on 7/9/22.
//

import SwiftUI

struct NoteView: View {
    //@State var test:String="Hello world"
    @StateObject var samples : WaterSampleViewModel
    @Binding var i : Int
    @FocusState private var foc : Bool
    @State var ori=""
    @Binding var noteSheet : Bool
    
    var body: some View {
        GeometryReader{geometry in
            HStack(alignment:.center){
                Spacer()
                VStack{
                    //Spacer()
                    HStack{
                        Button(role:.cancel) {
                            //print("cancel")
                            samples.samples[i].note=ori
                            noteSheet=false
                        } label: {
                            Text("Cancel")
                            //Image(systemName: "ellipsis.circle")
                                //.font(.system(size:25))
                                //.foregroundColor(.blue)
                        }
                        .padding(.all)
                        Spacer()
                        Button {
                            //print("save")
                            //print(foc)
                            noteSheet=false
                        } label: {
                            Text("Save")
                            //Image(systemName: "plus.square.on.square")
                                //.font(.system(size:25))
                                //.foregroundColor(.blue)
                        }
                        .padding(.all)
                    }
                    HStack{
                        Text("Note:")
                            .font(.headline)
                            .padding([.leading,.top], 20)
                        Spacer()
                    }
                    TextEditor(text: $samples.samples[i].note)
                        .focused($foc)
                    .cornerRadius(10)
                        //.frame(width: geometry.size.width-30, height: (geometry.size.width-100)*0.4)
                        //.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: geometry.size.width)
                    .padding([.leading, .trailing, .bottom],10)
                        .onAppear {
                            ori = samples.samples[i].note
                            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                                foc=true
                                print("appear")
                                print(foc)
                            }
                        }
                    Spacer()
                }
                Spacer()
            }
            .background(Color(white:0.9))
            //.background(lGrey)
            .interactiveDismissDisabled()
        }
    }
}

/*
struct NoteView_Previews: PreviewProvider {
    static var previews: some View {
        NoteView()
    }
}
*/
