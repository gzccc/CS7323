//
//  ServerManager.swift
//  MachineLearning
//
//  Created by Zicheng Geng on 2022/5/1.
//

import UIKit


let ServerUrl = "http://192.168.1.218:8000/"

class ServerManager: NSObject {
    
    class  func post(vc:UIViewController, parm:Any,url:String,finish:@escaping (_ succeed:Bool,_ result:Any)->Void) {
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        
        // more time for http to train the model and send it back
        sessionConfig.timeoutIntervalForRequest = 15
        
        let session = URLSession(configuration: sessionConfig)
        //URL
        var request = URLRequest(url: URL(string: ServerUrl + url)!)
        
        request.httpMethod = "POST"
        // set cookies for authentication
        
        let token =  UserDefaults.standard.value(forKey: "TOKEN") as? String ?? ""
        request.setValue(token, forHTTPHeaderField: "Cookie")
        
        request.httpShouldHandleCookies = true
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: parm, options: .prettyPrinted)
        HubView.shared.show(vc.view)
        let task = session.dataTask(with: request) {(data, response, error) in
            do{
                HubView.shared.dismiss()
                if(error != nil){
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                
                
                if data != nil{
                    if let jsonObj:NSDictionary = try JSONSerialization.jsonObject(with: data!, options: [.allowFragments, .mutableContainers , .mutableLeaves]) as? NSDictionary
                    {
                        DispatchQueue.main.async {
                            print("_______\(jsonObj)")
                            
                            if jsonObj["code"] as! Int == 0{
                                
                                finish(true,jsonObj)
                                
                            }else if jsonObj["code"] as! Int == 99{
                                
                                let authenVc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AuthenticationViewController") as! AuthenticationViewController
                                authenVc.modalPresentationStyle = .fullScreen
                                
                                vc.present(authenVc, animated: true)
                            }else{
                                
                                finish(false,jsonObj["msg"] as! String)
                            }
                        }
                        
                    }else{
                        
                        DispatchQueue.main.async {
                            finish(false,"data parsing failed")
                        }
                    }
                }else{
                    DispatchQueue.main.async {
                        finish(false,"Connection server failed")
                    }
                }
            }catch{
                DispatchQueue.main.async {
                    finish(false,error.localizedDescription)
                    print(error.localizedDescription)
                }
            }
        }
        task.resume()
    }
    
}
