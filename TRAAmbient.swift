//
//  TRAAmbient.swift
//  Compass
//
//  Created by Tomas Radvansky on 18/09/2015.
//  Copyright © 2015 Radvansky Solutions. All rights reserved.
//

import UIKit
import AVFoundation

extension UIColor {
    var components:(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r,g,b,a)
    }
}

@IBDesignable class TRAAmbient: UIView,AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession?
    var videoOutput:AVCaptureVideoDataOutput?
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit()
    {
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
        let videoDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        var captureDevice:AVCaptureDevice!
        
        for device in videoDevices{
            let device = device as! AVCaptureDevice
            if device.position == AVCaptureDevicePosition.Front {
                captureDevice = device
                break
            }
        }
        
        do
        {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if (captureSession!.canAddInput(input))
            {
                captureSession!.addInput(input)
                videoOutput = AVCaptureVideoDataOutput()
                videoOutput!.videoSettings = NSDictionary(object: NSNumber(unsignedInt: kCVPixelFormatType_32BGRA), forKey: kCVPixelBufferPixelFormatTypeKey as NSString) as [NSObject : AnyObject]
                videoOutput!.alwaysDiscardsLateVideoFrames = true
                let cameraQueue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL)
                videoOutput!.setSampleBufferDelegate(self, queue: cameraQueue)
                captureSession!.addOutput(videoOutput)
                captureSession!.startRunning()
                
            }
        }
        catch
        {
            
            
        }
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer!, 0)
        
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer!, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!)
        let width = CVPixelBufferGetWidth(imageBuffer!)
        let height = CVPixelBufferGetHeight(imageBuffer!)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue).rawValue | CGBitmapInfo.ByteOrder32Little.rawValue
        
        let context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, bitmapInfo)
        let imageRef = CGBitmapContextCreateImage(context)
        CVPixelBufferUnlockBaseAddress(imageBuffer!, 0)
        
        
        let data:NSData = CGDataProviderCopyData(CGImageGetDataProvider(imageRef))!
        
        let pixels = UnsafePointer<UInt8>(data.bytes)
        
        
        var totalLuminascance = 0.0
        for x in 0...Int(width-1) {
            for y in 0...Int(height-1) {
                let pixelInfo: Int = ((Int(width) * Int(x)) + Int(y)) * 4
                let r = CGFloat(pixels[pixelInfo]) / CGFloat(255.0)
                let g = CGFloat(pixels[pixelInfo+1]) / CGFloat(255.0)
                let b = CGFloat(pixels[pixelInfo+2]) / CGFloat(255.0)
                let a = CGFloat(pixels[pixelInfo+3]) / CGFloat(255.0)
                let luminance:Double = Double(((r * 0.299) + (g * 0.587) + (b * 0.114))*a)
                totalLuminascance += luminance
            }
        }
        let finalValue = totalLuminascance / Double((width*height))
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            self.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(CGFloat(1.0 - finalValue))
        })
    }
    
}
