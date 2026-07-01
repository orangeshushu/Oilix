//
//  History.swift
//  Oilix
//
//  Created by Guo, Congyu on 1/30/22.
//

import Foundation
import SwiftUI
import MapKit
import Alamofire

struct sampleHist: Identifiable{
    let id = UUID()
    let date: Date
    //let latitude: Double
    //let longitude: Double
    let locat: CLLocationCoordinate2D?
    //let locatStr: String
    let result: String
    let notes: String
    let disperseX:Double
    let disperseY:Double
    let path: String
    let tags: String
}

struct HistoryResponseFail: Codable {
    var status: Int
    var msg: String
}


struct HistoryResponse: Codable {
    let status: Int
    struct HistoryRecord: Codable{
        let id: Int?
        let path: String
        let gps: String
        let date: String
        let result: String?
        let notes: String
        let tags: String?
    }
    //let msg: [HistoryRecord]
    let msg: Dictionary<Int,HistoryRecord>
    struct HistoryMeta: Codable{
        let total_page: Int
        let current_page: Int
        let attempted_username: String
    }
    let meta: HistoryMeta
}

class History:ObservableObject{
    @Published var data = [sampleHist]()
    var j1:HistoryResponse?
    
    static func getLocation(locStr:String)->CLLocationCoordinate2D?{
        let vowels:Set<Character> = [" "]
        var ls=locStr
        ls.removeAll(where:{vowels.contains($0)})
        let loc=ls.components(separatedBy: ",")
        if loc.count != 2
        {
            return nil
        }
        guard let la:Double=Double(loc[0]) else {return nil}
        guard let lo:Double=Double(loc[1]) else {return nil}
        let ret = CLLocationCoordinate2D(latitude: la, longitude: lo)
        return ret
    }
    
    func getHistory(){
        //dummyData(amont: 20)
        getFromServer()
    }
    /*
    func dummyData(amont:Int){
        for i in 0..<20{
            data.append(sampleHist(date:Date(timeIntervalSince1970: Double.random(in: 1609459200...1644936187)), locat:CLLocationCoordinate2D(latitude:Double.random(in: 32.5 ... 48.9),longitude:Double.random(in: -117.2 ... -81.4)), result:"114514" ,notes: "dummy", disperseX: Double.random(in: -0.0007...0.0007), disperseY: Double.random(in: -0.0007...0.0007), path: "https://missouri.edu/images/signatures/university/MUstacked.png", tags: "#dummy"))
        }
        //print("dummy data got")
        print(data.count)
    }
    */
    func getFromServer()//->Bool
    {
        print("server")
        let url=URL(string: serverURL+"history")!
        //let url=URL(string:"https://wateroil.itongue.cn/history")!
        //let url=URL(string:"http://47.100.22.28/history")!
        //var urlRequest = URLRequest(url: url)
        
        
        
        AF.request(url, method: .post, encoding: JSONEncoding.default, headers: nil)
            .validate(statusCode: 200 ..< 299)
            .responseJSON { AFdata in
                do {
                    /*
                    struct TokenPair: Codable {
                        var refresh: String
                        var access: String
                    }
                     */
                    
                    
                    
                    
                    //print(AFdata.data! as NSData)
                    //print(String(decoding:AFdata.data!, as: UTF8.self))//Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value
                    guard let dvj=AFdata.data else{
                        print("Error: Cannot unwarp data")
                        return
                    }
                    /*
                    var recCount = -2
                    dvj.forEach { by in
                        if by==123
                        {
                            recCount+=1
                        }
                    }
                    print("records:\(recCount)")
                     */
                    
                    /*
                    //dvj.insert(91, at: 21)
                    dvj[21]=91
                    //dvj[dvj.count-2]=93
                    //var cur=22
                    var sw=1
                    var dn=22
                    while dn<dvj.count {
                        //if dvj[dn] == 93{
                         //   break
                        //}else
                        if dvj[dn] == 123{
                            sw=0
                            dn+=1
                        }else if dvj[dn] == 125{
                            sw=1
                            dn+=3
                        }else if sw == 1{
                            dvj.remove(at: dn)
                        }else{
                            dn+=1
                        }
                        if(dvj[dn]==125 && dvj[dn+1]==125)
                        {
                            dvj[dn+1]=93
                            break
                        }
                    }
                    print(String(decoding:dvj, as: UTF8.self))
                     */
                    
                    guard let jsonObject = try JSONSerialization.jsonObject(with: dvj) as? [String: Any] else {//Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value
                        print("Error: Cannot convert data to JSON object")
                        return
                    }
                    //print(jsonObject["msg"])
                    //let sms=jsonObject["msg"]!
                    //print(sms)
                    //jsonObject.count
                    guard let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
                        print("Error: Cannot convert JSON object to Pretty JSON data")
                        return
                    }
                    print(prettyJsonData as NSData)
                    print(String(decoding:prettyJsonData, as: UTF8.self))
                    self.j1 =  try JSONDecoder().decode(HistoryResponse.self, from: prettyJsonData)
                    print(self.j1!.msg.count)
                } catch {
                    print("Error: Trying to convert JSON data to string-h")
                    //showsAlert=true
                    //self.showAlert=true
                    return
                }
                //showsAlert=false
                //print("logged")
                //self.isLoggedIn=true
                //self.showAlert=false
                //let defaults = UserDefaults()
                //defaults.set(self.name,forKey: "username")
                //defaults.set(self.psw,forKey: "password")
                //defaults.set(self.access,forKey: "access")
                //self.err=false
                let dateform=DateFormatter()
                dateform.dateFormat="yyyy-MM-dd"
                var historyItems = [sampleHist]()
                for hm in self.j1!.msg {
                    /*
                    print(hm.date)
                    self.data.append(sampleHist(
                        date: dateform.date(from: hm.date)!,
                        //locat: CLLocationCoordinate2D(latitude:Double.random(in: 32.5 ... 48.9),longitude:Double.random(in: -117.2 ... -81.4)),
                        locat: History.getLocation(locStr: hm.gps),
                        //locatStr: hm.gps,
                        result: hm.result ?? "",
                        notes: hm.notes,
                        disperseX: Double.random(in: -0.0007...0.0007),
                        disperseY: Double.random(in: -0.0007...0.0007),
                        path: hm.path,
                        tags: hm.tags ?? ""))
                     */
                    
                    print(hm.value.date)
                    historyItems.append(sampleHist(
                        date: dateform.date(from: hm.value.date)!,
                        //locat: CLLocationCoordinate2D(latitude:Double.random(in: 32.5 ... 48.9),longitude:Double.random(in: -117.2 ... -81.4)),
                        locat: History.getLocation(locStr: hm.value.gps),
                        //locatStr: hm.gps,
                        result: hm.value.result ?? "",
                        notes: hm.value.notes,
                        disperseX: Double.random(in: -0.0007...0.0007),
                        disperseY: Double.random(in: -0.0007...0.0007),
                        path: hm.value.path,
                        tags: hm.value.tags ?? ""))

                }
                self.data = historyItems.sorted { $0.date > $1.date }
            }
    }
     
}
