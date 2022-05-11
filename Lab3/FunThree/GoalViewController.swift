//
//  GoalViewController.swift
//  Try3
//
//  Created by Zicheng on 2021/12/6.
//

import Foundation
import UIKit

class GoalViewController:UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var GoalNumTextField: UITextField!
    @IBOutlet weak var GoalConfirmButton: UIButton!
    
    let motion = {
        return MotionModel.sharedInstance()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GoalNumTextField.text = "\(self.motion.getDailyGoal())"
        GoalNumTextField.delegate = self
        GoalNumTextField.keyboardType = .numberPad
        
    }
    
    //Show number keyboard when inputting Daily Goal
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let invalidCharacters = CharacterSet(charactersIn: "0123456789").inverted
        return string.rangeOfCharacter(from: invalidCharacters) == nil
    }
    
    //set the goal and permanently store
    @IBAction func GoalConfirmTap(_ sender: Any) {
        motion.dailyGoalSet(dailyGoal: self.GoalNumTextField.text ?? "")
        dismiss(animated: true, completion: nil)
    }
    
}
