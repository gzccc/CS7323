//
//  MotionModel.swift
//  Try3
//
//
//
//  Created by Zicheng on 2021/12/6.
//

import Foundation
import CoreMotion

//extend the Date
extension Date {
    var dayBefore: Date {//Yesterday
        return Calendar.current.date(byAdding: .day, value: -1, to: midnight)!
    }
    var midnight: Date {//midnight
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }
}

// set extension name of notification
extension Notification.Name {
    static let didReceiveTodaySteps = Notification.Name("didReceiveTodaySteps")// today steps
    static let didReceiveYesterdaySteps = Notification.Name("didReceiveYesterdaySteps") // yesterday steps
    static let didReceiveDailyGoal = Notification.Name("didReceiveDailyGoal") // daily goal
    static let didReceiveCurrentMotion = Notification.Name("didReceiveCurrentMotion") // current motion
}

class MotionModel {
    
    // MARK: Properties
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    let customQueue = OperationQueue()
    
    let DAILY_GOAL = "DailyGoal" // key to store daily goal
    let YESTERDAY_MARK = "YesterDayMark"
    let CURRENCY = "StepsToCurrency"
    
    private var todaySteps:Int {
        didSet { // when value changed, send notification to observers
            NotificationCenter.default.post(name: .didReceiveTodaySteps, object: nil)
        }
    }
    private var yesterdaySteps:Int {
        didSet { // when value changed, send notification to observers
            NotificationCenter.default.post(name: .didReceiveYesterdaySteps, object: nil)
        }
    }
    private var motionDesc : String
    private var dailyGoal : Int {
        didSet { // when value changed, send notification to observers
            NotificationCenter.default.post(name: .didReceiveDailyGoal, object: nil)
        }
    }
    private var currency : Int
    
    private static let singleInstance: MotionModel = {
       let shared = MotionModel()
        return shared
    }() // return single instance
    
    
    init() {
        self.yesterdaySteps = MotionModel.initYesterdaySteps()
        self.todaySteps = 0
        self.motionDesc = ""
        self.dailyGoal = UserDefaults.standard.integer(forKey: DAILY_GOAL)// if daily goal does not set, 0 will be assigned.
        
        // if yesterday's goal was achieved, give 10 + yesterday's steps as currency
        self.currency = 0
    }
    
    class func sharedInstance() -> MotionModel {
        return singleInstance
    }
    
    
    // set daily goal and store the value
    func dailyGoalSet(dailyGoal:String) {
        self.dailyGoal = Int(dailyGoal) ?? 0
        UserDefaults.standard.set(self.dailyGoal, forKey: DAILY_GOAL)
    }
    
    // get daily goal
    func getDailyGoal() -> Int {
        return self.dailyGoal
    }
    
    //start activity updates
    func startActivityUpdates() {
        if CMMotionActivityManager.isActivityAvailable() {
            self.activityManager.startActivityUpdates(to: customQueue) {
            (activity:CMMotionActivity?) -> Void in
                if let unwrappedActivity = activity {
                    self.motionDesc = ""
                    print(unwrappedActivity.description)
                    if unwrappedActivity.walking {
                        self.motionDesc += "walking"
                    }
                    if unwrappedActivity.running {
                        self.motionDesc += "running"
                    }
                    if unwrappedActivity.unknown {
                        self.motionDesc += "unknown"
                    }
                    if unwrappedActivity.stationary {
                        self.motionDesc += "stationary"
                    }
                    if unwrappedActivity.cycling {
                        self.motionDesc += "cycling"
                    }
                    if unwrappedActivity.automotive {
                        self.motionDesc += "on automobile"
                    }
                    if self.motionDesc == "" {
                        self.motionDesc = "unknown"
                    }
                    
                    NotificationCenter.default.post(name: .didReceiveCurrentMotion, object: nil)
                }
            }
        }
    }
    
    // start pedometer updates
    func startPedometerUpdates() {
        if CMPedometer.isStepCountingAvailable() {
            self.pedometer.startUpdates(from: Date().midnight) { (pedData:CMPedometerData?, error:Error?) in
                if pedData != nil {
                    self.todaySteps = Int(truncating: pedData!.numberOfSteps)
                }
            }
        }
    }
    
    // return a string description of current motion
    // return empty string if CMMotionActivityManager is inactive
    func getCurrentMotion() -> String {
        return self.motionDesc
    }
    
    //stop activity updates
    func stopActivityUpdates() {
        if CMMotionActivityManager.isActivityAvailable(){
            self.activityManager.stopActivityUpdates()
        }
    }
    
    // stop pedometer updates
    func stopPedometerUpdates() {
        if CMPedometer.isStepCountingAvailable() {
            self.pedometer.stopUpdates()
        }
    }
    
    // get steps of yesterday
    func getYesterdaySteps() -> Int {
        if self.yesterdaySteps > 0 {
            return self.yesterdaySteps
        }
        if CMPedometer.isStepCountingAvailable() {
            self.pedometer.queryPedometerData(from: Date().dayBefore, to: Date().midnight) {
                (pedData: CMPedometerData?,error:Error?) -> Void in
                if pedData?.numberOfSteps != nil {
                    self.yesterdaySteps = Int(truncating: pedData!.numberOfSteps)
                } else {
                    self.yesterdaySteps = 0
                }
            }
        }
        return self.yesterdaySteps
    }
    
    // get steps of today
    func getTodaySteps() -> Int {
        return self.todaySteps
    }
    
    // get today's goal state description
    // if goal achieved, then return "Goal reached!"
    // else return how many steps remaining
    func getTodayGoalStateDesc() -> String {
        var goalDesc = ""
        if self.dailyGoal <= self.todaySteps {
            goalDesc = "Goal reached!" // if goal is reached
        } else {
            
            goalDesc = "\(self.dailyGoal - self.todaySteps) steps left!"  // if goal is not reached
        }
        return goalDesc
    }
    
    // get yesterday's goal state descrption
    func getYesterdayGoalStateDesc() -> String {
        var goalDesc = ""
        if self.dailyGoal <= self.yesterdaySteps {
            goalDesc = "Goal reached!"
        } else {
            goalDesc = "\(self.dailyGoal - self.yesterdaySteps) steps left!"
        }
        return goalDesc
    }
    
    //whether yesterday's steps meet the daily goal, return true if yes
    //return false if not
    func isYesterdayGoalReached() -> Bool {
        var isReached = false
        if self.yesterdaySteps >= self.dailyGoal {
            isReached = true
        }
        return isReached
    }
    
    // update currency, return true if successfully
    func updateCurrency(number:Int) -> Bool {
        if self.currency + number >= 0 {
            self.currency += number
            UserDefaults.standard.set(self.currency, forKey: CURRENCY)
            return true
        } else {
            return false
        }
    }
    
    func getCurrency() -> Int {
        return self.currency
    }
    
    // set up currency
    func setUpCurrency() {
        let yesterdayMark = UserDefaults.standard.string(forKey: YESTERDAY_MARK)
        if yesterdayMark == nil || yesterdayMark != Date().dayBefore.description(with: .current) {
            self.currency = 10+yesterdaySteps
            UserDefaults.standard.set(Date().dayBefore.description(with: .current), forKey: YESTERDAY_MARK)
            UserDefaults.standard.set(self.currency, forKey: CURRENCY)
        } else {
            self.currency = UserDefaults.standard.integer(forKey: CURRENCY)+10
        }
    }
    
    // get yesterday steps
    private static func initYesterdaySteps() -> Int {
        var yesterdaySteps: Int = 0
        if CMPedometer.isStepCountingAvailable() {
            CMPedometer().queryPedometerData(from: Date().dayBefore, to: Date().midnight) {
                (pedData: CMPedometerData?,error:Error?) -> Void in
                if pedData?.numberOfSteps != nil {
                    yesterdaySteps = Int(truncating: pedData!.numberOfSteps)
                    print("pedData yesterdaySteps \(yesterdaySteps) \(pedData!.numberOfSteps)")
                } else {
                    yesterdaySteps = 0
                }
            }
        }
        return yesterdaySteps
    }
}
