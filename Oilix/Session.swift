//
//  Session.swift
//  Oilix
//
//  Created by Guo, Congyu on 11/22/21.
//

import Foundation
import Alamofire
//import SwiftUI

class Session: ObservableObject{
    @Published var isLoggedIn: Bool = false
    @Published var showAlert: Bool = false
    @Published var loading=false
    @Published var msg="null"
    //var err=false
    @Published var access:String = ""
    @Published var refresh:String = ""
    @Published var disperse:Bool{
        didSet{
            UserDefaults.standard.set(disperse, forKey: "disperse")
        }
    }
    @Published var deleteConfirm:Bool{
        didSet{
            UserDefaults.standard.set(deleteConfirm, forKey: "deleteConfirm")
        }
    }
    var name=""
    var psw=""
    
    init(){
        self.disperse=UserDefaults.standard.object(forKey: "disperse") as? Bool ?? true
        self.deleteConfirm=UserDefaults.standard.object(forKey: "deleteConfirm") as? Bool ?? true
    }
    
    func testLogin()
    {
        self.showAlert=false
        print("testlogin")
        self.isLoggedIn=true
        let defaults = UserDefaults()
        defaults.set("notLogIn",forKey: "username")
        defaults.set("",forKey: "password")
        defaults.set("",forKey: "access")
    }
    
    func login()//->Bool
    {
        //let url=URL(string:"http://66.42.127.2:3000/api/auth/token/obtain/")!
        //let url=URL(string:"http://45.63.68.161/api/auth/token/obtain/")!
        //let url=URL(string:"http://47.100.22.28/api/auth/token/obtain/")!
        //let url=URL(string:"http://47.100.22.28/login2")!
        //let url=URL(string:"http://47.100.22.28/login2?username=admin&password=admin")!
        //let url=URL(string:"http://192.168.0.133")!
        
        //var urlRequest = URLRequest(url: url)
        //urlRequest.method = .post
        
        
        //let parameters=nil
        //print("Hello!")
        isLoggedIn=false
        //showAlert=true
        
        //let ds="{\"username\": \"admin\", \"password\": \"admin2\"}"
        //let pjson = ds.toJSONString(prettyPrint: false)
        //let data = (ds.data(using: .utf8))! as Data
        //urlRequest.httpBody=data
        
        //let url=URL(string:"https://wateroil.itongue.cn/login")!
        let url=URL(string: serverURL+"login")!
        //let url=URL(string:"https://47.100.22.28/login")!
        //let url=URL(string:"https://119.45.163.114/login")!
        //let url=URL(string:"http://47.100.22.28/login")!
        let parameters=["username":name,"password":psw]
        struct LoginResponse: Codable {
            var status: Int
            var msg: String
            struct meta: Codable{
                let username: String
                let name: String
                let email: String
            }
            //var msg: String
        }
        //var j1:LoginResponse=LoginResponse(status: 9, msg: "")
        //var j1:LoginResponse?
        var j1:LoginResponse=LoginResponse(status: 9, msg: "")
        //AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil)
        AF.request(url, method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder(destination: .httpBody), headers: nil)
            .validate(statusCode: 200 ..< 299)
            .responseJSON { AFdata in
                do {
                    /*
                     struct TokenPair: Codable {
                     var refresh: String
                     var access: String
                     }
                     */
                    //print("do")
                    //print(AFdata.response?.statusCode)
                    self.loading=false
                    if(AFdata.data==nil){
                        print("AFdata.data is nil")
                        self.showAlert=true
                        self.msg="Network error. Please try again."
                        return
                    }
                    
                    print(String(decoding:AFdata.data!, as: UTF8.self))//Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value
                    guard let jsonObject = try JSONSerialization.jsonObject(with: AFdata.data!) as? [String: Any] else {//Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value
                        print("Error: Cannot convert data to JSON object")
                        return
                    }
                    guard let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
                        print("Error: Cannot convert JSON object to Pretty JSON data")
                        return
                    }
                    j1 = try JSONDecoder().decode(LoginResponse.self, from: prettyJsonData)
                    //print(j1.msg)
                    //self.access=j1.access
                    //self.refresh=j1.refresh
                    //showsAlert=false
                    //tab()
                } catch {
                    print("Error: Trying to convert JSON data to string")
                    //showsAlert=true
                    self.msg="Network error. Please try again."//maybe server 500
                    self.showAlert=true
                    return
                }
                //showsAlert=false
                if j1.status==0{
                    print("logged")
                    self.isLoggedIn=true
                    self.showAlert=false
                    let defaults = UserDefaults()
                    defaults.set(self.name,forKey: "username")
                    defaults.set(self.psw,forKey: "password")
                    //defaults.set(self.access,forKey: "access")
                }else{
                    self.showAlert=true
                    self.msg=j1.msg
                }
                //self.err=false
            }
        //print("fin")
        //print(isLoggedIn)
        //return isLoggedIn
    }
    
    func logout(){
        
        //let url=URL(string:"https://wateroil.itongue.cn/logout")!
        let url=URL(string: serverURL+"logout")!
        
        AF.request(url, method: .get, encoding: JSONEncoding.default, headers: nil)
            .validate(statusCode: 200 ..< 299)
            .responseJSON { AFdata in
                do {
                    struct LogoutResponse: Codable {
                        var status: Int
                        var msg: String
                    }
                    if(AFdata.data==nil){
                        print("AFdata.data is nil")
                        return
                    }
                    //print(String(decoding:AFdata.data!, as: UTF8.self))
                    guard let jsonObject = try JSONSerialization.jsonObject(with: AFdata.data!) as? [String: Any] else {//Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value
                        print("Error: Cannot convert data to JSON object")
                        return
                    }
                    guard let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
                        print("Error: Cannot convert JSON object to Pretty JSON data")
                        return
                    }
                    let j1:LogoutResponse =  try JSONDecoder().decode(LogoutResponse.self, from: prettyJsonData)
                    print(j1.msg)
                } catch {
                    print("Error: Trying to convert JSON data to string")
                    //showsAlert=true
                    self.showAlert=true
                    return
                }
                print("loggout")
                self.isLoggedIn=false
                self.showAlert=false
                //let defaults = UserDefaults()
                //defaults.set(self.name,forKey: "username")
                //defaults.set(self.psw,forKey: "password")
                //defaults.set(self.access,forKey: "access")
                //self.err=false
            }
        
        name=""
        psw=""
        //access=""
        //refresh=""
    }
    
    func deleteUser(){
        let url=URL(string: serverURL+"deleteuser")!
        
        AF.request(url, method: .post, encoding: JSONEncoding.default, headers: nil)
            .validate(statusCode: 200 ..< 299)
            .responseJSON { AFdata in
                do {
                    struct LogoutResponse: Codable {
                        var status: Int
                        var msg: String
                    }
                    if(AFdata.data==nil){
                        print("AFdata.data is nil")
                        return
                    }
                    guard let jsonObject = try JSONSerialization.jsonObject(with: AFdata.data!) as? [String: Any] else {
                        print("Error: Cannot convert data to JSON object")
                        return
                    }
                    guard let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
                        print("Error: Cannot convert JSON object to Pretty JSON data")
                        return
                    }
                    let j1:LogoutResponse =  try JSONDecoder().decode(LogoutResponse.self, from: prettyJsonData)
                    print(j1.msg)
                } catch {
                    print("Error: Trying to convert JSON data to string")
                    //showsAlert=true
                    self.showAlert=true
                    return
                }
                print("user deleted")
                self.isLoggedIn=false
                self.showAlert=false
            }
        name=""
        psw=""
    }
    
}
