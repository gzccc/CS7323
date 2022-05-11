//
//  AddViewController.swift
//  HTTPSwiftExample
//
//  Created by M on 2022/5/7.
//  Copyright © 2022 Eric Larson. All rights reserved.
//

import UIKit
import CoreMotion

class AddViewController: UIViewController {

    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var largeMotionMagnitude: UIProgressView!
    
    var magValue = 0.1
    var ringBuffer = RingBuffer()
    let motion = CMMotionManager()
    var buttonArray = [UIButton]()
    var labelArray = ["up","right","down","left"]
    var currentSelectButton = 0
    
    // MARK: Class Properties
    lazy var session: URLSession = {
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        
        sessionConfig.timeoutIntervalForRequest = 5.0
        sessionConfig.timeoutIntervalForResource = 8.0
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        return URLSession(configuration: sessionConfig)
    }()
  
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.view.endEditing(true)
    }
    
    @IBOutlet weak var dsidTextFiled: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        buttonArray = [upButton,rightButton,downButton,leftButton]
        
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 1.0/200
            self.motion.startDeviceMotionUpdates(to: OperationQueue()) { motionData, error in
                
                if let accel = motionData?.userAcceleration {
                    self.ringBuffer.addNewData(xData: accel.x, yData: accel.y, zData: accel.z)
                    let mag = fabs(accel.x)+fabs(accel.y)+fabs(accel.z)
                    
                    DispatchQueue.main.async{
                        //show magnitude via indicator
                        self.largeMotionMagnitude.progress = Float(mag)/0.2
                    }
                    
                    if mag > self.magValue {
                                             
                    }
                }
            }
        }
        
    }
    
    @IBAction func magnitudeChanged(_ sender: UISlider) {
        self.magValue = Double(sender.value)
    }
    
    @IBAction func directionButtonClick(_ sender: UIButton) {
        
        for button in buttonArray{
            
            if button == sender{
                
                self.currentSelectButton = sender.tag
                button.backgroundColor = .red
            }else{
                button.backgroundColor = .white
            }
        }
    }
    
    @IBAction func addButtonClick(_ sender: Any) {
        
        if (dsidTextFiled.text!.count == 0){
            
            alertTipsWith(msg: "DSID can not be empty")
            return
        }
        
        if currentSelectButton == 0{
         
            alertTipsWith(msg: "select one Calibrate button please")
            return
        }
        
        print("----\(self.buttonArray[currentSelectButton-10].titleLabel!.text!)--\(labelArray[currentSelectButton-10])")
        
      
        
        // Comm with Server
        var request = URLRequest(url: URL(string:"\(SERVER_URL)/AddDataPoint")!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature":self.ringBuffer.getDataAsVector(),
                                       "label":"\(labelArray[currentSelectButton-10])",
                                       "dsid":self.dsidTextFiled.text!]
        
        request.httpMethod = "POST"
        request.httpBody = try! JSONSerialization.data(withJSONObject: jsonUpload, options: .prettyPrinted)
        
       self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    if let res = response{
                        print("Response:\n",res)
                    }
                }else{

                    let jsonDictionary:NSDictionary = try! JSONSerialization.jsonObject(with: data!, options: [.allowFragments, .mutableContainers , .mutableLeaves]) as! NSDictionary

                        print(jsonDictionary)
                }
       }).resume()
    }
    
    //MARK: JSON Conversion Functions
    func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
        do { // try to make JSON and deal with errors using do/catch block
            let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
            return requestBody
        } catch {
            print("json error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func alertTipsWith(msg:String){
        DispatchQueue.main.async{
            let alertVC = UIAlertController(title: msg, message: nil, preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .cancel)
            alertVC.addAction(alertAction)
            self.present(alertVC, animated: true)
        }
    }

}
