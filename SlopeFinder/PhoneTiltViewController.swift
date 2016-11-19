//
//  FirstViewController.swift
//  SlopeFinder
//
//  Created by Nathan Lambson on 11/18/16.
//  Copyright © 2016 Nathan Lambson. All rights reserved.
//

import UIKit
import CoreMotion

class PhoneTiltViewController: UIViewController {

    let motionKit = MotionKit()
    @IBOutlet weak var slopeInDegreesLabel: UILabel!
    var lastYaw: Double = 0.0
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        lastYaw = 0.0
        motionKit.getDeviceMotionObject(0.01) { (deviceMotion) in
            self.deviceMoved()
        }
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        motionKit.stopDeviceMotionUpdates()
    }
    
    func deviceMoved() {
        motionKit.getAttitudeAtCurrentInstant { (attitude) in
            let quat: CMQuaternion = attitude.quaternion
            let yaw: Double = asin(2 * (quat.x * quat.z - quat.w * quat.y))
            
            if self.lastYaw == 0 {
                self.lastYaw = yaw
            }
            
            // kalman filtering
            let q: Double = 0.1 // process noise
            let r: Double = 0.1 // sensor noise
            var p: Double = 0.1 // estimated error
            var k: Double = 0.5 // kalman filter gain
            
            var x: Double = self.lastYaw
            p = p + q
            k = p / (q + r)
            x = x + k * (yaw - x)
            p = (1 - k) * p
            self.lastYaw = x
        }
        
        slopeInDegreesLabel.text = String(format: "%.1f°", fabs(self.lastYaw))
    }

}

