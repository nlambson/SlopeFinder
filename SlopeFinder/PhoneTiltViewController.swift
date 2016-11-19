//
//  FirstViewController.swift
//  SlopeFinder
//
//  This class is used to determine the slope of an object by placing an iPhone
//  parallel to the inclined object
//
//
//  Created by Nathan Lambson on 11/18/16.
//  Copyright © 2016 Nathan Lambson. All rights reserved.
//

import UIKit
import CoreMotion

class PhoneTiltViewController: UIViewController {

    let motionKit = MotionKit()
    @IBOutlet weak var slopeInDegreesLabel: UILabel!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        motionKit.getDeviceMotionObject(0.01) { (deviceMotion) in
            self.slopeInDegreesLabel.text = String(format: "%.1f°", deviceMotion.attitude.pitch.radiansToDegrees.double)
        }
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        motionKit.stopDeviceMotionUpdates()
    }
    

}

