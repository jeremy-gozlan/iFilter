//
//  ViewController.swift
//  iFilter
//
//  Created by Jeremy on 16/11/2019.
//  Copyright © 2019 Jeremy. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import SwiftImage

// Capture View
// This view makes all the camera features possible ( capture, galery, zooming, autofocus, reset).

class ViewController: UIViewController,UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    // My segmentation model
    let vgg_unet = unet3()
    
    // camera attributes
    let cameraController = CameraController()
    var pivotPinchScale : CGFloat = 0.0
    var zoomGesture = UIPinchGestureRecognizer()
    let imagePickerController = UIImagePickerController()
    
    // captured image
    var imageToBeSegmented : UIImage?
    var croppedImage: UIImage?

    // view buttons
    @IBOutlet weak var captureButton: UIButton!
    
    @IBOutlet weak var capturePreviewView: UIView!
    
    @IBOutlet weak var libraryButton: UIButton!
    
    override var prefersStatusBarHidden: Bool { return true }
    
    // Set up the view.
    override func viewDidLoad()
    {
        //Instantiate the button
        styleCaptureButton()
        // Instantiate the square corners
        setBorder()
        // Instantiate and set up the camera.
        configureCameraController()
        // Zoom/Autofocus
        addZoomAndPinch()
        // Image galery access setup
        setupLibrary()
           
    }
    
}

// SEGMENTATION

extension ViewController
{
    
    // This function resizes the image outputed image which is smaller than the input.
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    // Perfom the segmentation with the formatted cropped image.
    
    func performSegmentation(pixelBuffer: CVPixelBuffer) -> Image<RGBA<UInt8>>
    {
        // Prediction
        guard let modelOutput = try? vgg_unet.prediction(img: pixelBuffer) else
        {
             fatalError("Unexpected runtime error.")
        }
        // 1D array output corresponding to the pixels.
        let dictModelOutput = modelOutput.output1
        var list = [RGBA<UInt8>]()
        let range : CountableClosedRange = 0...(dictModelOutput.count/2)-1
        // For each array value, create a corresponding pixel color.
        for i in range
        {
            // Background = black
            if dictModelOutput[i*2] as! Float > 0.5
            {
                list.append(RGBA(red: 0, green: 0, blue: 0, alpha: 255))
            }
            // Sneakers = Blue
            else
            {
                list.append(RGBA(red: 0, green: 255, blue: 255, alpha: 255))
            }
        }
        // Create the colorized image with those pixels.
        var sw_Image : Image<RGBA<UInt8>> = Image(width:304,height:208, pixels: list)
        
        return sw_Image
   }
}


// Image capture and reset.

extension ViewController
{
    
      // Capture an instant snapshot of the image, format it, segmented it and present the Segmentation View
      @IBAction func captureImage(_ sender: Any)
      {
          cameraController.captureImage {(image, error) in
              guard let image = image else {
                  print(error ?? "Image capture error")
                  return
              }
            
             self.imageToBeSegmented = image
            
             let formattedImage = self.formatImageForSegmentation()
             let segmentedImage = self.performSegmentation(pixelBuffer: formattedImage!)
             let convertedImage = Image<RGBA<UInt8>>(uiImage: self.croppedImage!)
             let alert = SegmentationAlertView(croppedImage: convertedImage, segmentedImage : segmentedImage)
              alert.show(animated: true)
              
 
          }
      }
      
      
      @IBAction func deleteCurrentImage(_ sender: Any)
      {
          self.imageToBeSegmented = nil
          print("deleted")
      }
    
    
    
}


// CAMERA SETUP
extension ViewController
{
    func configureCameraController() {
        cameraController.prepare {(error) in
            if let error = error {
                print(error)
            }
            
            try? self.cameraController.displayPreview(on: self.capturePreviewView)
            
        
        }
    }
}

// IMAGE LIBRARY SETUP
extension ViewController
{
    
    func setupLibrary()
    {
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = false
        imagePickerController.sourceType = .photoLibrary
    }
    
    // Create the button actions when pushing the galery button.
    @IBAction func showLibrary(_ sender: Any)
    {
       
        let actionSheet = UIAlertController(title:"Photo Source",message:"Import image from library",preferredStyle:.actionSheet)
                   
        actionSheet.addAction(UIAlertAction(title:"Photo Library",style:.default,handler:{ (action:UIAlertAction) in self.imagePickerController.sourceType = .photoLibrary
            self.present(self.self.imagePickerController,animated:true,completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title:"Cancel",style:.cancel ,handler:nil))
                   
       self.present(actionSheet,animated:true,completion:nil)
               
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
       {
           picker.dismiss(animated : true, completion : nil)
       }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
    
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
         {
            /*self.imageToBeSegmented = pickedImage
            var formattedImage = self.formatImageForSegmentation()
            let segmentedImage = self.performSegmentation(pixelBuffer: formattedImage!)
            let convertedImage = Image<RGBA<UInt8>>(uiImage: self.croppedImage!)
            let alert = SegmentationAlertView(croppedImage: convertedImage, segmentedImage : segmentedImage)
             alert.show(animated: true)
           */
            
         }
     
        dismiss(animated: true, completion: nil)
    }
    
}

// Extensions UIImage
extension UIImage
{
      func crop( rect: CGRect) -> UIImage {
          var rect = rect
          rect.origin.x*=self.scale
          rect.origin.y*=self.scale
          rect.size.width*=self.scale
          rect.size.height*=self.scale

          let imageRef = self.cgImage!.cropping(to: rect)
          let image = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
         
          return image
      }
  }

extension UIImage {
    var isPortrait:  Bool    { size.height > size.width }
    var isLandscape: Bool    { size.width > size.height }
    var breadth:     CGFloat { min(size.width, size.height) }
    var breadthSize: CGSize  { .init(width: breadth, height: breadth) }
    var squared: UIImage? {
        guard let cgImage = cgImage?
            .cropping(to: .init(origin: .init(x: isLandscape ? ((size.width-size.height)/2).rounded(.down) : 0,
                                              y: isPortrait  ? ((size.height-size.width)/2).rounded(.down) : 0),
                                size: breadthSize)) else { return nil }
        return UIGraphicsImageRenderer(size: breadthSize, format: imageRendererFormat).image { _ in
            UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation)
            .draw(in: .init(origin: .zero, size: breadthSize))
        }
    }
}

extension ViewController
{
    // Format an image to be a cropped pixel buffer version of it. This is needed as the segmentation model requires such formatting.

    func formatImageForSegmentation() -> CVPixelBuffer?
    {
        // Crop the snapshot to square corners.
        let cropRect = CGRect(x: 0, y: self.imageToBeSegmented!.size.height/4 - 100 , width: self.imageToBeSegmented!.size.width, height: self.imageToBeSegmented!.size.height/2 + 200)
        let croppedImage = self.cameraController.imageWithImage(image: self.imageToBeSegmented!, croppedTo: cropRect)
        self.croppedImage = croppedImage
        
        // Resize the cropped image to the model input shape and make it a pixelbuffer.
        let modelWidth = 608
        let modelHeight = 416
        UIGraphicsBeginImageContextWithOptions(CGSize(width: modelWidth, height: modelHeight), true, 1.0)
        croppedImage.draw(in: CGRect(x: 0, y: 0, width: modelWidth, height: modelHeight ))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        //guard (status == kCVReturnSuccess)
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
                 
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
                 
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
                 
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
        
    }
    
    
    
    
}

// ZOOM AND PINCH
extension ViewController
{
    func addZoomAndPinch()
    {
        capturePreviewView.isMultipleTouchEnabled = true
    
        self.zoomGesture.delegate = self
        self.zoomGesture = UIPinchGestureRecognizer(target: self, action:#selector(pinchRecognized))
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapGesture(tap:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.delegate = self
        
        capturePreviewView.addGestureRecognizer(singleTapGesture)
        capturePreviewView.addGestureRecognizer(self.zoomGesture)
       
    }
    
    // Recognize a pinch gesture for the zooming functionality
    @IBAction func pinchRecognized(pinch: UIPinchGestureRecognizer)
    {
        
        do {
            try cameraController.rearCamera?.lockForConfiguration()
            switch pinch.state {
            case .began:
                self.pivotPinchScale = CGFloat(cameraController.rearCamera!.videoZoomFactor)
            case .changed:
                var factor = self.pivotPinchScale * pinch.scale
                factor = max(1, min(factor, (cameraController.rearCamera?.activeFormat.videoMaxZoomFactor)!))
                cameraController.rearCamera?.videoZoomFactor = factor
            default:
                break
            }
            cameraController.rearCamera?.unlockForConfiguration()
        } catch {
            
        }
        
    }
    
    // Recognize a simple tap on the Capture View for the autofocus functionality.
    @objc func singleTapGesture(tap: UITapGestureRecognizer)
    {
        // Find the tap location
        let screenSize = self.view!.bounds.size
        let tapPoint = tap.location(in:self.capturePreviewView)
        let x = tapPoint.x / screenSize.width
        let y = tapPoint.y / screenSize.height
        let focusPoint = CGPoint(x: x, y: y)
        
        let focusPointForFocus = CGPoint(x: tapPoint.y / screenSize.height, y: 1.0 - tapPoint.x / screenSize.width)
        
        if let device = cameraController.rearCamera {
            do {
               
                try device.lockForConfiguration()
                let squareTemporaryView = UIView()
                
                print(focusPoint)
                let focusPointModif = CGPoint(x:focusPoint.x * UIScreen.main.bounds.width-40.0 ,y:focusPoint.y*UIScreen.main.bounds.height-40.0)
                
                squareTemporaryView.frame = CGRect(origin: focusPointModif, size: CGSize(width: 80, height: 80))
                
                // Show the autofocus region
                squareTemporaryView.layer.borderWidth = CGFloat(1)
                let yourViewBorder = CAShapeLayer()
                yourViewBorder.strokeColor = UIColor.white.cgColor
                yourViewBorder.lineDashPattern = [2, 2]
                yourViewBorder.frame = squareTemporaryView.bounds
                yourViewBorder.fillColor = nil
                yourViewBorder.path = UIBezierPath(rect: squareTemporaryView.bounds).cgPath
                squareTemporaryView.layer.addSublayer(yourViewBorder)
                self.capturePreviewView.addSubview(squareTemporaryView)
                squareTemporaryView.layer.borderColor = UIColor.white.cgColor
                self.capturePreviewView.bringSubviewToFront(squareTemporaryView)
                
                if device.isFocusPointOfInterestSupported == true {
                    device.focusPointOfInterest = focusPointForFocus
                    device.focusMode = .autoFocus
                    
                }
                // Perform focus.
                device.exposurePointOfInterest = focusPointForFocus
                device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                let when = DispatchTime.now() + 0.5 // change 2 to desired number of seconds
                DispatchQueue.main.asyncAfter(deadline: when) {
                    squareTemporaryView.removeFromSuperview()
                }
                device.unlockForConfiguration()
                
            }
            catch {
            }
            
        }
    }

}

// DASHED AND TAKE PICTURE BUTTON STYLES
extension ViewController {
    
    // Dashed aspect
    func addDashedLine(p0 : CGPoint, p1: CGPoint)
    {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.lineDashPattern = [12, 4] // 7 is the length of dash, 3 is length of the gap.
        let path = CGMutablePath()
        path.addLines(between: [p0, p1])
        shapeLayer.path = path
        self.capturePreviewView.layer.addSublayer(shapeLayer)
    }
    
    // Square corner borders.
    func setBorder()
    {
        
        //TOP LEFT CORNER
        var p0 = CGPoint(x: 30, y: capturePreviewView.bounds.height/4)
        var p1 = CGPoint(x: 60, y: capturePreviewView.bounds.height/4)
        var p2 = CGPoint(x: 30, y: capturePreviewView.bounds.height/4 + 30)
        addDashedLine(p0: p0, p1: p1)
        addDashedLine(p0: p0, p1: p2)
        
        //TOP RIGHT CORNER
        p0 = CGPoint(x: self.capturePreviewView.bounds.width - 30, y: capturePreviewView.bounds.height/4)
        p1 = CGPoint(x: self.capturePreviewView.bounds.width - 60, y: capturePreviewView.bounds.height/4)
        p2 = CGPoint(x: self.capturePreviewView.bounds.width - 30, y: capturePreviewView.bounds.height/4 + 30)
        addDashedLine(p0: p0, p1: p1)
        addDashedLine(p0: p0, p1: p2)
        
        //BOTTOM LEFT CORNER
        p0 = CGPoint(x: 30, y: capturePreviewView.bounds.height*3/4)
        p1 = CGPoint(x: 60, y: capturePreviewView.bounds.height*3/4)
        p2 = CGPoint(x: 30, y: capturePreviewView.bounds.height*3/4 - 30)
        addDashedLine(p0: p0, p1: p1)
        addDashedLine(p0: p0, p1: p2)
        
        //BOTTOM LEFT CORNER
        p0 = CGPoint(x: self.capturePreviewView.bounds.width - 30, y: capturePreviewView.bounds.height*3/4)
        p1 = CGPoint(x: self.capturePreviewView.bounds.width - 60, y: capturePreviewView.bounds.height*3/4)
        p2 = CGPoint(x: self.capturePreviewView.bounds.width - 30, y: capturePreviewView.bounds.height*3/4 - 30)
        addDashedLine(p0: p0, p1: p1)
        addDashedLine(p0: p0, p1: p2)
        
    }
    
    func styleCaptureButton()
    {
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.layer.borderWidth = 4
        captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height) / 2
    }
    
    
}


