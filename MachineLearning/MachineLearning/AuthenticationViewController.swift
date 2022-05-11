//
//  AuthenticationViewController.swift
//  MachineLearning
//
//  Created by Zicheng Geng on 2022/5/2.
//

import UIKit

class AuthenticationViewController: UIViewController {

    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

            
    }
    
  
    @IBAction func logInButtonClick(_ sender: Any) {
        
        self.startAuthenticationFromServer(param: ["username":userNameTextField.text!,"password":passwordTextField.text!])
    }
    
    func startAuthenticationFromServer(param:[String:String]){
        
        ServerManager.post(vc:self,parm: param, url: "auth/login") { succeed, result in
            
            if succeed{
                
                if (result as! NSDictionary)["code"] as! Int == 0{
                    
                    UserDefaults.standard.setValue((result as! NSDictionary)["TOKEN"], forKey: "TOKEN")
                    UserDefaults.standard.synchronize()
                    
                    self.dismiss(animated: true)
                }
            }else{
                
                HubView.shared.show(message: result as! String)
            }
        }
    }
    
  
   
   
}
