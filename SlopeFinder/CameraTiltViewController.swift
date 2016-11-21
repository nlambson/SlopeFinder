//
//  SecondViewController.swift
//  SlopeFinder
//
//  This class is used for visually dtermining the slope of a distant incline
//  The red line auto adjusts for camera shake or tilt, the slider is how to
//  adjust the slope. Instead of forcing the camera to focus at 100 yards per
//  the requirement, I implemented autofocus and tap to focus
//
//  Created by Nathan Lambson on 11/18/16.
//  Copyright © 2016 Nathan Lambson. All rights reserved.
//

import UIKit
import CoreMotion
import AVFoundation


class CameraTiltViewController: UIViewController {
    @IBOutlet var slopeView: UIView!
    
    @IBOutlet weak var yawSlopeSlider: UISlider!
    @IBOutlet weak var yawSlopeLabel: UILabel!
    @IBOutlet weak var pitchSlopeSlider: UISlider!
    @IBOutlet weak var pitchSlopeLabel: UILabel!
    
    let motionKit = MotionKit()
    var captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    let tapRecognizer = UITapGestureRecognizer() //to focus camera
    
    // If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    
    // MARK: ViewController Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        yawSlopeSlider.backgroundColor = UIColor.clearColor()
        yawSlopeSlider.minimumTrackTintColor = UIColor.redColor()
        yawSlopeSlider.maximumTrackTintColor = UIColor.redColor()
//        yawSlopeSlider.setThumbImage(UIImage(named: "verticalLine"), forState: .Normal)
        
        pitchSlopeSlider.backgroundColor = UIColor.clearColor()
        pitchSlopeSlider.minimumTrackTintColor = UIColor.blackColor()
        pitchSlopeSlider.maximumTrackTintColor = UIColor.blackColor()
        
        pitchSlopeSlider.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2));
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureDevice != nil {
            beginSession()
        }
        
        
        
        motionKit.getDeviceMotionObject(0.03) {[weak self] (deviceMotion) in
            //yaw
            let gravity = deviceMotion.gravity
            let quat = deviceMotion.attitude.quaternion
            let yaw = asin(2*(quat.x*quat.z - quat.w*quat.y))
            var yawDegrees = yaw.radiansToDegrees.double
            
            if (abs(yawDegrees) > 90) {
                let remainder = yawDegrees % 90
                yawDegrees -= remainder * 2
            }
            
            self!.yawSlopeSlider.setValue(Float(yawDegrees), animated: false)
            self!.yawSlopeLabel.text = String(format: "%.1f°", abs(yawDegrees))
            
            //pitch
            let r = sqrt(gravity.x*gravity.x + gravity.y*gravity.y + gravity.z*gravity.z)
            var pitchDegrees = acos(gravity.z/r) * 180.0 / M_PI - 90.0
            
            if (abs(pitchDegrees) > 90) {
                let remainder = pitchDegrees % 90
                pitchDegrees -= remainder * 2
            }
            
            self!.pitchSlopeSlider.setValue(Float(pitchDegrees), animated: false)
            self!.pitchSlopeLabel.text = String(format: "%.1f°", abs(pitchDegrees))
        }
        
        //Make sure your controls are visible after loading the camera preview
        self.view.bringSubviewToFront(yawSlopeLabel)
        self.view.bringSubviewToFront(yawSlopeSlider)
        self.view.bringSubviewToFront(pitchSlopeSlider)
        self.view.bringSubviewToFront(pitchSlopeLabel)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // clean up
        motionKit.stopDeviceMotionUpdates()
        captureSession.stopRunning()
        captureSession = AVCaptureSession()
    }
    
    // MARK: AVCapture and preview
    func beginSession() {
       
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        } catch _ {
            print("💩 hit the fan, couldn't add AVCaptureDeviceInput")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        if let previewLayer = previewLayer {
            self.view.layer.addSublayer(previewLayer)
            previewLayer.frame = self.view.layer.frame
            captureSession.startRunning()
            
            tapRecognizer.addTarget(self, action: #selector(self.tapped(_:)))
            self.view.addGestureRecognizer(tapRecognizer)
            self.view.userInteractionEnabled = true
        }
    }
    
    // MARK: focus camera methods - ignored 100 yard requirement for auto focus and tap to focus
    func tapped(sender: UITapGestureRecognizer) {
        if sender.state == .Ended {
            focusTo(sender.locationInView(self.view))
        }
    }
    
    func focusTo(focusPoint: CGPoint) {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = focusPoint
                device.focusMode = .AutoFocus
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = AVCaptureExposureMode.ContinuousAutoExposure
                device.unlockForConfiguration()
            } catch _ {
                print("💩 hit the fan trying to focus")
            }
        }
    }
    
    // MARK: ASValueTracking methods
//    func slider(slider: ASValueTrackingSlider!, stringForValue value: Float) -> String! {
//        currentAngle = CGFloat(value)
//        return String(format: "%.1f°", value)
//    }
}
