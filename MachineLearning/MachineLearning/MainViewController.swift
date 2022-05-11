//
//  MainViewController.swift
//  MachineLearning
//
//  Created by Zicheng Geng on 2022/5/5.
//

import UIKit
import PhotosUI
import CoreML
import CoreMotion
import Photos
import MobileCoreServices

class MainViewController: UIViewController {
    
    ///current select ImageView tag
    var currentSelectTag = 10
    
    /// total Label  From Model
    var totalLabelCount = 0
    
    var scissorsCount = 0
    var rockCount = 0
    var paperCount = 0
    // A predictor instance that uses Vision and Core ML to generate prediction strings from a photo.
    let imagePredictor = ImagePredictor()
    
    @IBOutlet weak var paperCountLabel: UILabel!
    @IBOutlet weak var rockCountLabel: UILabel!
    @IBOutlet weak var scissorsCountLabel: UILabel!
    
    @IBOutlet weak var scissorsPlayImg: UIImageView!
    @IBOutlet weak var paperTipsLabel: UILabel!
    @IBOutlet weak var rockTipsLabel: UILabel!
    @IBOutlet weak var scissorsTipsLabel: UILabel!
    
    @IBOutlet weak var rockPlayImg: UIImageView!
    @IBOutlet weak var paperImageView: UIImageView!
    @IBOutlet weak var rockImageView: UIImageView!
    @IBOutlet weak var scissorsImageView: UIImageView!
    
    @IBOutlet weak var paperPlayImg: UIImageView!
    @IBOutlet weak var predictTipsButton: UIButton!
    @IBOutlet weak var predictLogisticImageView: UIImageView!
    @IBOutlet weak var predictBoostedImageView: UIImageView!
    @IBOutlet weak var predictLogisticPlayImg: UIImageView!
    @IBOutlet weak var predictBoostedPlayImg: UIImageView!
    
    @IBOutlet weak var logisticResultLabel: UILabel!
    @IBOutlet weak var boostedResultLabel: UILabel!
    
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var modelTypeSegment: UISegmentedControl!
    
    var currentImageArray = [UIImage]()
    
    //use it on taking photo
    var imagePickerController:UIImagePickerController!
    
    // initialize pre-trained boosted decision tree model
    var boostedTreeClassifier:boosted_model = {
        do{
            let config = MLModelConfiguration()
            return try boosted_model(configuration: config)
        }catch{
            fatalError("App failed to create an boostedTree model instance.")
        }
    }()
    
    // initialize pre-trained logistic regression model
    var logisticClassifier:logistic_model = {
        do{
            let config = MLModelConfiguration()
            return try logistic_model(configuration: config)
        }catch{
            fatalError("App failed to create an logistic model instance.")
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.authUser()
        getLabelCountFromServer()
        
    }
    // MARK: ---- Auth----
    func authUser(){
        
        ServerManager.post(vc:self, parm: [:], url: "auth") { succeed, result in
        }
    }
    
    func getLabelCountFromServer(){
        
        totalLabelCount = 0
        ServerManager.post(vc:self, parm: [:], url: "model/getModelData") { succeed, result in
            
            if (succeed){
                let data = ((result as! NSDictionary)["data"] as! String).data(using: String.Encoding.utf8)
                if let dict = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String : Any] {
                    
                    if (dict["scissors"] != nil){
                        self.scissorsCountLabel.text = "Count:\(dict["scissors"] as? Int ?? 0)"
                        self.totalLabelCount += 1
                        self.scissorsCount = dict["scissors"] as? Int ?? 0
                    }
                    if (dict["rock"] != nil){
                        self.rockCountLabel.text = "Count:\(dict["rock"] as? Int ?? 0)"
                        self.totalLabelCount += 1
                        self.rockCount = dict["rock"] as? Int ?? 0
                    }
                    if (dict["paper"] != nil){
                        self.paperCountLabel.text = "Count:\(dict["paper"] as? Int ?? 0)"
                        self.totalLabelCount += 1
                        self.paperCount = dict["paper"] as? Int ?? 0
                    }
                }
            }else{
                
                HubView.shared.show(message: result as! String)
            }
        }
    }
    
    /// Notifies the view controller when a user selects a photo in the camera picker or photo library picker.
    /// - Parameter photo: A photo from the camera or photo library.
    func userSelectedPhoto(_ photo: UIImage) {
        
        DispatchQueue.main.async{
            
            switch self.currentSelectTag {
            case 10:
                self.scissorsPlayImg.isHidden = false
                self.scissorsTipsLabel.isHidden = true
                self.scissorsImageView.image = photo
                
            case 11:
                self.rockPlayImg.isHidden = false
                self.rockTipsLabel.isHidden = true
                self.rockImageView.image = photo
                
            case 12:
                self.paperPlayImg.isHidden = false
                self.paperTipsLabel.isHidden = true
                self.paperImageView.image = photo
                
            case 13:
                self.predictTipsButton.setTitle("", for: .normal)
                self.predictLogisticImageView.image = photo
                self.predictLogisticPlayImg.isHidden = false
                self.predictBoostedPlayImg.isHidden = false
                self.predictBoostedImageView.image = photo
                
            default:
                break
            }
        }
    }
    
    @IBAction func selectPhoto(_ sender: UITapGestureRecognizer) {
        
        let imageV = sender.view as! UIImageView
        currentSelectTag = imageV.tag
        
        openCamera(index: 2)
    }
    
    //open camera function
    func openCamera(index:Int){
        imagePickerController=UIImagePickerController()
        //make sure the media source is not unavailable.
        
        //basic setting
        self.imagePickerController!.delegate = self
        self.imagePickerController!.allowsEditing = true
        self.imagePickerController!.sourceType = .camera;
        if index==1{//take photo if index == 1
            self.imagePickerController?.mediaTypes=[kUTTypeImage as String]
        }else if index==2{//take video if index == 2
            self.imagePickerController?.mediaTypes=[kUTTypeMovie as String]
        }
        // else open the photo library
        else {                       self.imagePickerController?.mediaTypes=UIImagePickerController.availableMediaTypes(for: UIImagePickerController.SourceType.photoLibrary)!
        }
        //present camera interface
        self.present(self.imagePickerController!, animated: true, completion: nil)
    }
    
    // MARK: ---- Train----
    @IBAction func trainButtonClick(_ sender: Any) {
        
        if totalLabelCount < 3   {
            
            HubView.shared.show(message: "have not image to train,submit at least one image!")
            return
            
        }
        ServerManager.post(vc:self, parm: [:], url: "model/trainModel") { succeed, result in
            
            if succeed{
                
                HubView.shared.show(message: "train successed")
            }else{
                HubView.shared.show(message: "train failed")
            }
        }
    }
    // MARK: ---- Predict----
    @IBAction func predictButtonClick(_ sender: UIButton) {
        
        if predictLogisticImageView.image == nil{
            
            HubView.shared.show(message: "select image frist")
            return
        }
        
        if modelTypeSegment.selectedSegmentIndex == 0{
            for image in currentImageArray{
                
                guard let data =  image.transformImageToRGBData() else {
                    
                    HubView.shared.show(message: "transform data failed")
                    return
                }
                
                ServerManager.post(vc:self,parm: ["modelName":sender.tag == 131 ? "logistic_model" : "boosted_model","feature":data], url: "model/predict") { succeed, result in
                    
                    HubView.shared.dismiss()
                    if succeed{
                        
                        if (result as! NSDictionary)["code"] as! Int == 0{
                            
                            let res =  (result as! NSDictionary)["data"] as! String
                            if (sender.tag == 131){
                                self.logisticResultLabel.text = "Result:" + res
                            }else{
                                self.boostedResultLabel.text = "Result:" +  res
                            }
                        }
                    }else{
                        HubView.shared.show(message: result as! String)
                    }
                }
            }
          
        }else{
            for image in currentImageArray{
             
                self.classifyImage(image, model: sender.tag == 131 ? 0 :1)
            }
           
        }
    }
    // MARK: ---- TrainAndCompare----
    @IBAction func trainAndCompareButtonClick(_ sender: Any) {
        if totalLabelCount < 3 || scissorsCount < 2 || rockCount < 2 || paperCount < 2 {
            
            HubView.shared.show(message: "requires each label have at least 3 images!")
            return
            
        }
        ServerManager.post(vc:self,parm: [:], url: "model/TrainAndCompareModel") { succeed, result in
            
            HubView.shared.dismiss()
            if succeed{
                
                if (result as! NSDictionary)["code"] as! Int == 0{
                    
                    HubView.shared.show(message: "train and Compare model success!")
                    let dict = (result as! NSDictionary)["data"] as! [String:String]
                    self.accuracyLabel.text = "Logistic accuracy: \(dict["logistic_acc"]!)\nBoosted tree accuracy: \(dict["boosted_acc"]!)"
                }
            }else{
                HubView.shared.show(message: result as! String)
            }
        }
    }
    
    // MARK: ---- AddPredictImage----
    @IBAction func addPredictImageButtonClick(_ sender: UIButton) {
        
        currentSelectTag = 13
        
        openCamera(index: 2)
    }
    // MARK: ---- submitImageToModel----
    @IBAction func submitImageButtonClick(_ sender: UIButton) {
        
        let selectImageV =   self.view.viewWithTag(sender.tag/10) as! UIImageView
        if selectImageV.image == nil{
            
            HubView.shared.show(message: "select image frist")
            return
        }
        
        print("submit count --\(selectImageV.image)")
        
        for image in currentImageArray{
            
            guard let data =  image.transformImageToRGBData() else {
                
                HubView.shared.show(message: "transform data failed")
                return
            }
            
            var label = ""
            
            if (sender.tag == 100){
                
                label = "scissors"
            }else if (sender.tag == 110){
                
                label = "rock"
            }else if (sender.tag == 120){
                
                label = "paper"
            }
            print("add label-->> \(label)")
            
            ServerManager.post(vc:self,parm:  ["feature":data , "label": label] as [String : Any], url: "uploadImage") { succeed, result in
                if succeed{
                    
                    if (result as! NSDictionary)["code"] as! Int == 0{
                        
                        HubView.shared.show(message: "submit success")
                        self.getLabelCountFromServer()
                    }
                }else{
                    HubView.shared.show(message: result as! String)
                }
            }
        }
    }
    
}

extension MainViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    //camera
    // MARK: ---imagePickerController Delegete----
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated:true, completion:nil)
        
        //get the photo just took, sand save it
        let type:String = (info[UIImagePickerController.InfoKey.mediaType]as!String)
        if type=="public.image"{
            let img = info[UIImagePickerController.InfoKey.originalImage]as?UIImage
            
            if img != nil{
                let dataString =  img!.jpegData(compressionQuality: 0.8)!.base64EncodedString()
                
                self.userSelectedPhoto(img!)
                // addPicToPlist(imageDataString: dataString, videoString: nil, type: 0)
                
            }else{
                print("No Selected Image")
            }
        }else if type == "public.movie"{
            //record video and save it
            let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
            if url != nil{
                
                self.splitVideo(fileUrl: url!, fps: 1)
            }
        }
    }
    
    func splitVideo(fileUrl:URL,fps:Float){
        
        let asset = AVURLAsset.init(url: fileUrl, options: nil)
        
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        
        var times = [NSValue]()
        let totalFrames:Int = Int(Float(durationSeconds)  * fps)
        
        var  timeFrame = CMTime()
        for i in 1...totalFrames{
            
            timeFrame = CMTimeMake(value: Int64(i), timescale: Int32(fps))
            times.append(NSValue(time: timeFrame))
        }
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        
        imgGenerator.requestedTimeToleranceBefore = CMTime.zero
        imgGenerator.requestedTimeToleranceAfter = CMTime.zero
        
        self.currentImageArray.removeAll()
        imgGenerator.generateCGImagesAsynchronously(forTimes: times) { requestedTime, image, actualTime, result, error in
            
            self.userSelectedPhoto(UIImage(cgImage: image!))
            self.currentImageArray.append(UIImage(cgImage: image!).cropToSize())
            
            print(self.currentImageArray)
        }
        
    }
    
}

extension MainViewController {
    // MARK: Image prediction methods
    /// Sends a photo to the Image Predictor to get a prediction of its content.
    /// - Parameter image: A photo.
    private func classifyImage(_ image: UIImage, model:Int) {
        
        // get the image and image data
        let seq = self.toMLMultiArray(image.transformImageToRGBData()!)
        var pred = "None"
        
        if (model == 0) {
            // using logistic regression
            guard let outputTuri = try? logisticClassifier.prediction(sequence: seq) else {
                fatalError("Unexpected runtime error.")
            }
            pred = outputTuri.target
        } else {
            // using boosted decision tree
            guard let outputTuri = try? boostedTreeClassifier.prediction(sequence: seq) else {
                fatalError("Unexpected runtime error.")
            }
            // update prediction
            pred = outputTuri.target
        }
        
        /// Updates the storyboard's prediction label.
        if model == 0{
            self.logisticResultLabel.text = "Result:" + pred
        }else{
            self.boostedResultLabel.text = "Result:" + pred
        }
    }
    
    // to MLMultiArray is for pre-trained coreml models
    func toMLMultiArray(_ arr: [Float]) -> MLMultiArray {
        // initialize sequence with required space
        guard let sequence = try? MLMultiArray(shape:[129600], dataType:MLMultiArrayDataType.double) else {
            fatalError("Unexpected runtime error. MLMultiArray could not be created")
        }
        let size = Int(truncating: sequence.shape[0])
        for i in 0..<size {
            // assign original array data to the new sequence
            sequence[i] = NSNumber(value: arr[i])
        }
        return sequence
    }
}


//https://stackoverflow.com/questions/33768066/get-pixel-data-as-array-from-uiimage-cgimage-in-swift
// extension for UIImage to get the pixel data from the image
extension UIImage {
    func transformImageToRGBData() -> [Float]? {
        
        let size = self.size
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData, width: Int(size.width),  height: Int(size.height),  bitsPerComponent: 8,  bytesPerRow: 4 * Int(size.width), space: colorSpace,   bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        var tmpArray:[Float] = []
        var grayscaled:Float = 0
        
        // calculate the gray from RGB channels and append to a temporary array
        // since the expressions are normally irrelvant with the image color
        for i in stride(from: 0, to: pixelData.count, by: 4){
            // The Weighted Method of RGB to grayscale
            grayscaled = 0.299*Float(pixelData[i]) + 0.587*Float(pixelData[i+1]) + 0.114*Float(pixelData[i+2])
            tmpArray.append(grayscaled)
            
            // skipping the alpha channel
        }
        print("tmpArray¥---\(tmpArray.count)")
        
        // dimension reduction for the image, skipping some of the pixels
        // since we don't want to overload the data passed to backend and excede database limit
        var returnArray:[Float] = []
        //        // from 1242*1242 to 207*207
        for i in stride(from: 0, to: 360, by: 1) {
            for j in stride(from: 0, to: 360, by: 1){
                if (i % 1 == 0 && j % 1 == 0) {
                    returnArray.append(tmpArray[j+i*360])
                } else { continue }
            }
        }
        return returnArray
    }
    func cropToSize() -> UIImage {
        var newRect = CGRect(x: 0, y: 0, width: 1242, height: 1242)
        newRect.origin.x *= self.scale
        newRect.origin.y *= self.scale
        newRect.size.width *= self.scale
        newRect.size.height *= self.scale
        let cgimage = self.cgImage?.cropping(to: newRect)
        let resultImage = UIImage(cgImage: cgimage!, scale: self.scale, orientation: self.imageOrientation)
        return resultImage
    }
    
}
