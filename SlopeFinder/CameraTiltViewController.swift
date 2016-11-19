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


class CameraTiltViewController: UIViewController, ASValueTrackingSliderDataSource {

    @IBOutlet var slopeView: UIView!
    @IBOutlet weak var horizontalLineView: UIView!
    @IBOutlet weak var slopeSlider: ASValueTrackingSlider!
    
    let motionKit = MotionKit()
    var currentAngle: CGFloat = 0.0
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
        
        slopeSlider.dataSource = self
        slopeSlider.setValue(0, animated: false)
        slopeSlider.popUpViewCornerRadius = 12.0
        slopeSlider.font = UIFont.init(name: "GillSans-Bold", size: 28)
        slopeSlider.backgroundColor = UIColor.clearColor()
        slopeSlider.minimumTrackTintColor = UIColor.whiteColor()
        slopeSlider.maximumTrackTintColor = UIColor.whiteColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureDevice != nil {
            beginSession()
        }
        
        motionKit.getDeviceMotionObject(0.01) { (deviceMotion) in
            let gravity = deviceMotion.gravity
            let rotation = atan2(gravity.x, gravity.y) - M_PI
            // for DEBUG
            // print(rotation.radiansToDegrees)
            self.horizontalLineView.transform = CGAffineTransformMakeRotation(CGFloat(rotation + self.currentAngle.degreesToRadians.double))
        }
        
        //Make sure your controls are visible after loading the camera preview
        self.view.bringSubviewToFront(horizontalLineView)
        self.view.bringSubviewToFront(slopeSlider)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // clean up
        motionKit.stopDeviceMotionUpdates()
        captureSession.stopRunning()
        captureSession = AVCaptureSession()
    }
    
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
    func slider(slider: ASValueTrackingSlider!, stringForValue value: Float) -> String! {
        currentAngle = CGFloat(value)
        return String(format: "%.1f°", value)
    }
}
