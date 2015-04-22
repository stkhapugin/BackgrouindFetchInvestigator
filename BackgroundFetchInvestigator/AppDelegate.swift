//
//  AppDelegate.swift
//  BackgroundFetchInvestigator
//
//  Created by Stepan Khapugin on 21/04/15.
//  Copyright (c) 2015 stepan khapugin. All rights reserved.
//

import UIKit
import Alamofire


class LogEvent : NSObject, Printable, NSCoding {
    
    let duration: Double
    let date: NSDate
    
    init(duration: Double, date: NSDate) {
        self.duration = duration
        self.date = date
        super.init()
    }
    
    override var description: String {
        return "Fetch at \(date) for \(duration) seconds"
    }
    
    required init(coder aDecoder: NSCoder) {
        self.duration = aDecoder.decodeDoubleForKey("duration")
        self.date = aDecoder.decodeObjectForKey("date") as! NSDate
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeDouble(self.duration, forKey: "duration")
        aCoder.encodeObject(self.date, forKey: "date")
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum);
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil))        
        schedulePostponeNotif()
        
        for event in self.fetchLog() {
            println(event)
        }

        return true
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        let start = NSDate()
        Alamofire.request(.GET, "http://stkhapugin.github.io")
            .response { (request, response, data, error) in
                
                let end = NSDate()
                let elapsed = end.timeIntervalSinceDate(start)
                self.logFetchEvent(elapsed)
                
                completionHandler(.NewData)
        }
    }
    
    private func schedulePostponeNotif() {
        
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        let notif = UILocalNotification()
        notif.alertAction = "No background fetches for 24 hours!"
        notif.alertBody = "No background fetches for 24 hours!"

        notif.fireDate = NSDate().dateByAddingTimeInterval(24*3600)
        
        UIApplication.sharedApplication().scheduleLocalNotification(notif)
    }
    
    private func fetchLog() -> [LogEvent] {
        var log : AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey("log")
        
        if log == nil {
            log = [LogEvent]()
        } else {
            log = NSKeyedUnarchiver.unarchiveObjectWithData(log as! NSData)
        }
    
        return log as! [LogEvent]
    }
    
    private func saveLog(log: [LogEvent]) {
        
        let archivedLog = NSKeyedArchiver.archivedDataWithRootObject(log)
        NSUserDefaults.standardUserDefaults().setObject(archivedLog, forKey: "log")
    }
    
    private func logFetchEvent(interval: Double) {
        
        var log = [LogEvent](fetchLog())
        log.append(LogEvent(duration: interval, date: NSDate()))
        
        let badgeCount = UIApplication.sharedApplication().applicationIconBadgeNumber
        UIApplication.sharedApplication().applicationIconBadgeNumber = badgeCount+1
        
        schedulePostponeNotif()
        
        self.saveLog(log)
    }

}

