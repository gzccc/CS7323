//
//  ViewController.swift
//  Try3
//
//  Created by Zicheng on 2021/12/6.
//

import UIKit

class ViewController: UIViewController {

    let motionModel = {
        return MotionModel.sharedInstance()
    }()
    
    @IBOutlet weak var TodayStepsLable: UILabel!
    @IBOutlet weak var YesterdayStepsLable: UILabel!
    @IBOutlet weak var CurrentMotionLable: UILabel!
    @IBOutlet weak var TodayGoalStateLable: UILabel!
    @IBOutlet weak var YesterdayGoalStateLable: UILabel!
    
    @IBOutlet weak var GoalSetButton: UIButton!
    @IBOutlet weak var DailyGameButton: UIButton!
    
    @IBAction func PressGameButton(_ sender: Any) {
        print("game starts")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        GoalSetButton.backgroundColor = .clear
        GoalSetButton.setTitleColor(UIColor.black, for: .normal)
        GoalSetButton.layer.cornerRadius = 5
        GoalSetButton.layer.borderWidth = 1
        GoalSetButton.layer.borderColor = UIColor.black.cgColor
        
        DispatchQueue.main.async {
            self.TodayStepsLable.text = "\(self.motionModel.getTodaySteps())"
            self.TodayGoalStateLable.text = "\(self.motionModel.getTodayGoalStateDesc())"
            self.YesterdayStepsLable.text = "\(self.motionModel.getYesterdaySteps())"
            self.YesterdayGoalStateLable.text = "\(self.motionModel.getYesterdayGoalStateDesc())"
            
            self.DailyGameButton.isEnabled = self.motionModel.isYesterdayGoalReached()
        }
        
        self.startActivityMonitoring()
        self.startPedometerMonitoring()
        self.startDailyGoalMonitoring()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //Do any additional setup after view disappeared
        
        motionModel.stopActivityUpdates()
        motionModel.stopPedometerUpdates()
    }
    
    // MARK: =====Motion Model Methods=====
    func startActivityMonitoring(){
        motionModel.startActivityUpdates()
//        Timer.scheduledTimer(
//            timeInterval: 1/20.0,
//            target: self,
//            selector: #selector(self.updateMotionLable),
//            userInfo: nil,
//            repeats: true)
        //here use NotificationCenter to update the lable.text
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveCurrentMotion(_:)), name: .didReceiveCurrentMotion, object: nil)
    }
    
    func startPedometerMonitoring(){
        motionModel.startPedometerUpdates()
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveTodaySteps(_:)), name: .didReceiveTodaySteps, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveYesterdaySteps(_:)), name: .didReceiveYesterdaySteps, object: nil)
    }
    
    // Daily goal changed monitoring
    func startDailyGoalMonitoring() {
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveDailyGoal(_:)), name: .didReceiveDailyGoal, object: nil)
    }
    
    @objc
    func updateMotionLable() {
        self.CurrentMotionLable.text = "Current Motion: \(self.motionModel.getCurrentMotion())"
        self.YesterdayStepsLable.text = "\(self.motionModel.getYesterdaySteps())"
        self.TodayStepsLable.text = "\(self.motionModel.getTodaySteps())"
    }
    
    //when receive the notification of today steps
    @objc func onDidReceiveTodaySteps(_ notification: Notification) {
        DispatchQueue.main.async {
            self.TodayStepsLable.text = "\(self.motionModel.getTodaySteps())"
            self.TodayGoalStateLable.text = "\(self.motionModel.getTodayGoalStateDesc())"
        }
    }
    
    //when receive the nofitication of yesterday steps
    @objc func onDidReceiveYesterdaySteps(_ notification: Notification) {
        DispatchQueue.main.async {
            self.YesterdayStepsLable.text = "\(self.motionModel.getYesterdaySteps())"
            self.YesterdayGoalStateLable.text = "\(self.motionModel.getYesterdayGoalStateDesc())"
            self.DailyGameButton.isEnabled = self.motionModel.isYesterdayGoalReached()
        }
    }
    
    //when receive the notification of daily goal
    @objc func onDidReceiveDailyGoal(_ notification: Notification) {
        print("daily goal changed \(notification)")
        print("\(self.motionModel.getYesterdayGoalStateDesc())")
        DailyGameButton.isEnabled = self.motionModel.isYesterdayGoalReached()
        DispatchQueue.main.async {
            self.YesterdayGoalStateLable.text = "\(self.motionModel.getYesterdayGoalStateDesc())"
            self.TodayGoalStateLable.text = "\(self.motionModel.getTodayGoalStateDesc())"
        }
    }
    
    // when receive the nofitication of current motion activity
    @objc func onDidReceiveCurrentMotion(_ notification: Notification) {
        DispatchQueue.main.async {
            self.CurrentMotionLable.text = "Current Motion: \(self.motionModel.getCurrentMotion())"
        }
    }
}

