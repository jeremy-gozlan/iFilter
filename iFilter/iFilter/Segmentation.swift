//
//  Segmentation.swift
//  iFilter
//
//  Created by Jeremy on 22/11/2019.
//  Copyright © 2019 Jeremy. All rights reserved.
//

import Foundation
import UIKit
import Photos
import SwiftImage
import QuartzCore

//  The segmentation view allows the user to apply filters to the segmented image given by the Capture View.
//  It has many filters that can be added individually to an image different parts.


class SegmentationAlertView : UIView, Modal
{
    // Parent view to put buttons, views and design of the segmentation view.
    var backgroundView = UIView()
    var dialogView = UIView()
    
    // Segmentation views for masks.
    var segmentationImageView = UIImageView()
    var segmentationImageView2 = UIImageView()
    var segmentationImageView3 = UIImageView()
    var filteringView = UIView()
    
    
    var saveButton = UIButton()
    
    let ciContext = CIContext()
    
    var currentSelection = "Background"
    
    var initialImage : Image<RGBA<UInt8>>?
    
    // Masks
    var resizedImageMask : Image<RGBA<UInt8>>?
    var smallResizedImageMask: Image<RGBA<UInt8>>?
    var temporaryMask: Image<RGBA<UInt8>>?
    var initialSegmentedImageMask : Image<RGBA<UInt8>>?
  
    // Filter lists
    var previousFilters : [FilterType] = []
    var previousFiltered : [UIImage] = []
    var previousFilterTag : [Int] = []
    
    var currentHeight : CGFloat = CGFloat(0)
    var width : CGFloat = UIScreen.main.bounds.width - 10
    
    var buttonViews : [UIView] = []
    
    // INIT
    convenience init(croppedImage: Image<RGBA<UInt8>>, segmentedImage: Image<RGBA<UInt8>>)
    {
        
        self.init(frame: UIScreen.main.bounds)
        
    
        self.initialImage = croppedImage
        self.initialSegmentedImageMask = segmentedImage
        
        
        self.previousFilters.append(FilterType.NoFilter)
        self.previousFiltered.append(croppedImage.uiImage)
    
        // Setup design and views.
        backgroundView.frame = frame
        backgroundView.backgroundColor = UIColor.black
        backgroundView.alpha = 0.6
        addSubview(backgroundView)
        
        // image views
        setupImageView()
        // create masks
        setupMasks()
        
        self.currentHeight += UIScreen.main.bounds.height/2 - 15
        self.currentHeight += 20
        
        // Filter buttons.
        setupFilterButtons()
        
        dialogView.frame.origin = CGPoint(x: 5, y: frame.height)
        dialogView.frame.size = CGSize(width: frame.width-10, height: currentHeight)
        dialogView.backgroundColor = UIColor.white
        dialogView.layer.cornerRadius = 6
        dialogView.clipsToBounds = true
        addSubview(dialogView)
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnBackgroundView)))
  
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    @objc func didTappedOnBackgroundView()
    {
        dismiss(animated: true)
    }
    
    // Gesture recognizer for the  view segmentation button. A long press shows the found sneakers pixels on the current filtered image.
    @objc func longPress(_ sender: UILongPressGestureRecognizer)
    {
        if (sender.state == .began)
        {
            print("pressing")
            
            self.segmentationImageView.image = self.temporaryMask?.uiImage
            
        }
        else
        {
            if (sender.state == .cancelled || sender.state == .failed || sender.state == .ended)
            {
                self.segmentationImageView.image = self.previousFiltered.last
                print("back")
                          
            }
        }
        
    }
    
    // Multiple masks where needed due to the discrepencies in size between the input image and segmented image ( pixel buffer discrepencies)
    func setupMasks()
    {
        //  BIG MASK
        
        UIGraphicsBeginImageContext(CGSize(width: 1080, height: 1160))
        var context1 = UIGraphicsGetCurrentContext()
        context1!.rotate(by: CGFloat(2*M_PI));
         
        self.segmentationImageView2.layer.render(in: context1!)
        
        var newUIImage1 = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.resizedImageMask = Image<RGBA<UInt8>>(uiImage: newUIImage1!)
        
        // SMALL MASK
               
        UIGraphicsBeginImageContext(self.segmentationImageView3.frame.size)
        var context2 = UIGraphicsGetCurrentContext()
        context2!.rotate(by: CGFloat(2*M_PI));
                
        self.segmentationImageView3.layer.render(in: context2!)
               
        var newUIImage2 = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
               
        self.smallResizedImageMask = Image<RGBA<UInt8>>(uiImage: newUIImage2!)
        
        // TEMPORARY MASK
        
        self.temporaryMask = self.initialImage!

        for x in 0...temporaryMask!.width-1
        {
            for y in 0...temporaryMask!.height-1
            {
                if self.resizedImageMask![x,y].green != 0
                {
                    temporaryMask![x,y].blue = 255
                    temporaryMask![x,y].green = 255
                }
            }
                          
        }
        
    }
    
    // When the long press is recognized on the image to select which part to apply filters.
    @objc func maskSelection(_sender : UILongPressGestureRecognizer)
    {
        let location = _sender.location(in: self.segmentationImageView)
        
        let x = Int(round(location.x))
        let y = Int(round(location.y))
        
        let pixel: RGBA<UInt8> = self.smallResizedImageMask![x,y]
        
        // Look at the mask pixel location and check whether it is a sneakers or background.
        var message = ""
        if pixel.green != 0
        {
            self.currentSelection = "Sneakers"
            message = "You selected sneakers"
        }
        else
        {
            self.currentSelection = "Background"
            message = "You selected the background"
        }
        
        
        let alert = UIAlertController(title: "iFilter", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
              switch action.style{
              case .default:
                    print("default")

              case .cancel:
                    print("cancel")

              case .destructive:
                    print("destructive")


        }}))
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        
    }
    
}


// iOS FILTERS

extension SegmentationAlertView
{
    // This function applies a selected filter to the currently filtered image.
    // In case the new filter to be appliec is the same as the last one, we only remove the last filter and do not apply the new one.
    
    func applyFilter(filter: FilterType, tag: Int)
    {
        // Remove last filter
        if (previousFilters.last == filter)
        {
           
            
            self.previousFilters.removeLast()
            self.previousFiltered.removeLast()
            self.segmentationImageView.image = self.previousFiltered.last
            
            for sub in buttonViews[tag].subviews
            {
                if let label = sub as? UILabel
                {
                    label.isHidden = true
                }
            }
            previousFilterTag.removeLast()
            
            if previousFilterTag.count != 0
            {
                for sub in buttonViews[previousFilterTag.last!].subviews
                {
                    if let label = sub as? UILabel
                    {
                        label.isHidden = false
                    }
                }
            }
            
        }
        // Apply new filter
        else
        {
            // Take currently displayed filtered image.
            let previousImage = Image<RGBA<UInt8>>(uiImage: self.previousFiltered.last!)
            var currentImage = Image<RGBA<UInt8>>(uiImage: self.previousFiltered.last!)
            
            // If special filters, apply them
            if( filter == .Canny)
            {
                currentImage = cannyFilter(img:currentImage)
            }
            else if ( filter == .Blur)
            {
                currentImage = blurFilter(img: currentImage)
            }
            else if ( filter == .Sharpen)
            {
                 currentImage = sharpenFilter(img: currentImage)
            }
            // iOS basic filters
            else
            {
               
                let f = CIFilter(name: filter.rawValue)
                let ciInput = CIImage(image: self.previousFiltered.last!)
                f?.setValue(ciInput, forKey: "inputImage")
                // get output CIImage, render as CGImage first to retain proper UIImage scale
                let ciOutput = f?.outputImage
                let cgImage = self.ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
                let filtered = UIImage(cgImage: cgImage!)
                currentImage = Image<RGBA<UInt8>>(uiImage: filtered)
            }
            
            // If sneakers is selected, only apply new image values to the sneakers pixels.
            if currentSelection == "Sneakers"
            {
                
                for x in 0...currentImage.width-1
                {
                    for y in 0...currentImage.height-1
                    {
                        if self.resizedImageMask![x,y].green == 0
                        {
                            currentImage[x,y] =  previousImage[x,y]
                        }
                        
                    }
                }
                   
            }
             // If background is selected, only apply new image values to the background pixels.
            else
            {
                for x in 0...currentImage.width-1
                {
                    for y in 0...currentImage.height-1
                    {
                        if self.resizedImageMask![x,y].green != 0
                        {
                            currentImage[x,y] =  previousImage[x,y]
                        }
                        
                    }
                }
                
            }
            
            // Append the new image and new filter to the lists.
            self.previousFilters.append(filter)
            self.previousFiltered.append(currentImage.uiImage)
            self.segmentationImageView.image = self.previousFiltered.last
            
            // Update labels.
            if previousFilterTag.count != 0
            {
                for sub in buttonViews[previousFilterTag.last!].subviews
                {
                    if let label = sub as? UILabel
                    {
                        label.isHidden = true
                    }
                }
            }
            
            
            for sub in buttonViews[tag].subviews
            {
               if let label = sub as? UILabel
                {
                    label.isHidden = false
                 }
            }
            
            previousFilterTag.append(tag)
            
        }
    }
    
    // Remove all applied filters and display the initial image.
    @objc func reset(sender: UIButton)
    {
        self.previousFilters = []
        self.previousFiltered = []
        self.previousFilters.append(FilterType.NoFilter)
        self.previousFiltered.append(self.initialImage!.uiImage)
        self.segmentationImageView.image = self.initialImage!.uiImage
        
        for button in buttonViews
        {
            for sub in button.subviews
            {
                if let label = sub as? UILabel
                {
                    label.isHidden = true
                }
            }
        }
            
    }
    
    // Save the displayed image.
    @objc func save(sender: UIButton)
    {
        try? PHPhotoLibrary.shared().performChangesAndWait{
            PHAssetChangeRequest.creationRequestForAsset(from: self.previousFiltered.last!)
        }
    }
    // iOS filters + custom
    enum FilterType : String {
    case Chrome = "CIPhotoEffectChrome"
    case Fade = "CIPhotoEffectFade"
    case Instant = "CIPhotoEffectInstant"
    case Mono = "CIPhotoEffectMono"
    case Noir = "CIPhotoEffectNoir"
    case Process = "CIPhotoEffectProcess"
    case Tonal = "CIPhotoEffectTonal"
    case Transfer =  "CIPhotoEffectTransfer"
    case Canny = "Canny"
    case Blur = "Blur"
    case Sharpen = "Sharpen"
    case NoFilter = ""
    }
    
    
    @objc func filter1(sender: UIButton)
    {
        applyFilter(filter: FilterType.Chrome,tag:0)
    }
    
    @objc func filter2(sender: UIButton)
    {
           
        applyFilter(filter: FilterType.Fade,tag:1)
    }
    
    @objc func filter3(sender: UIButton)
    {
        applyFilter(filter: FilterType.Instant,tag:2)
    }
    
    @objc func filter4(sender: UIButton)
    {
        applyFilter(filter: FilterType.Mono,tag:3)
    }
    
    @objc func filter5(sender: UIButton)
    {
           applyFilter(filter: FilterType.Noir,tag:4)
    }
       
    @objc func filter6(sender: UIButton)
    {
              
           applyFilter(filter: FilterType.Process,tag:5)
    }
       
    @objc func filter7(sender: UIButton)
    {
           applyFilter(filter: FilterType.Tonal,tag:6)
    }
       
    @objc func filter8(sender: UIButton)
    {
           applyFilter(filter: FilterType.Transfer,tag:7)
    }
    
    @objc func filter9(sender:UIButton)
    {
        applyFilter(filter: FilterType.Canny, tag: 8)
    }
    
    @objc func filter10(sender:UIButton)
    {
        applyFilter(filter: FilterType.Blur, tag: 9)
    }
    
    @objc func filter11(sender:UIButton)
    {
        applyFilter(filter: FilterType.Sharpen, tag: 10)
    }
    
    // Sharpen filter, use the unsharpmask
    func sharpenFilter(img: Image<RGBA<UInt8>>) -> Image<RGBA<UInt8>>
    {
        var image: Image<RGBA<UInt8>> = img
        
        var context = CIContext(options: nil)
        
        let currentFilter = CIFilter(name: "CIUnsharpMask")
        let beginImage = CIImage(image:image.uiImage)
        currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter!.setValue(4.0, forKey: kCIInputIntensityKey) //2
        currentFilter!.setValue(2.0, forKey: kCIInputRadiusKey) //1
        
        let output = currentFilter!.outputImage
        let cgimg = context.createCGImage(output!, from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!)
        var sharpened = Image<RGBA<UInt8>>(uiImage: processedImage)
                   
        return sharpened
    
    }
    
    // Use the gaussian blur filter
    func blurFilter(img: Image<RGBA<UInt8>>) -> Image<RGBA<UInt8>>
    {
        var image: Image<RGBA<UInt8>> = img
        
        var context = CIContext(options: nil)

        let currentFilter = CIFilter(name: "CIGaussianBlur")
        let beginImage = CIImage(image: image.uiImage)
        currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter!.setValue(10, forKey: kCIInputRadiusKey)

        let cropFilter = CIFilter(name: "CICrop")
        cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
        cropFilter!.setValue(CIVector(cgRect: beginImage!.extent), forKey: "inputRectangle")

        let output = cropFilter!.outputImage
        let cgimg = context.createCGImage(output!, from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!)
        var blurredImage = Image<RGBA<UInt8>>(uiImage: processedImage)
            
        return blurredImage
    }
    
    // Apply Canny filter as implemented in the TP 2  but with a swift implementation using Image library.
    func cannyFilter(img: Image<RGBA<UInt8>>) -> Image<RGBA<UInt8>>
    {
        var image: Image<RGBA<UInt8>> = img
        
        let grayscale: Image<Float> = image.map { Float($0.gray) }
        
        var gaussianKernel = Image<Int>(width: 5, height: 5, pixels: [
            1,  4,  6,  4, 1,
            4, 16, 24, 16, 4,
            6, 24, 36, 24, 6,
            4, 16, 24, 16, 4,
            1,  4,  6,  4, 1,
        ]).map { Float($0) / 256.0 }
        
        var blurred = grayscale.convoluted(with: gaussianKernel)
        
        var Ix = Image<Float>(width: grayscale.width,height:grayscale.height, pixels: [Float](repeating: 0.0, count: grayscale.width*grayscale.height))
        
        var Iy = Image<Float>(width: grayscale.width,height:grayscale.height, pixels: [Float](repeating: 0.0, count: grayscale.width*grayscale.height))
        
        var G2 = Image<Float>(width: grayscale.width,height:grayscale.height, pixels: [Float](repeating: 0.0, count: grayscale.width*grayscale.height))
        
        var Dx = Image<Float>(width: grayscale.width,height:grayscale.height, pixels: [Float](repeating: 0.0, count: grayscale.width*grayscale.height))
        
        var C = Image<Int>(width: grayscale.width,height:grayscale.height, pixels: [Int](repeating: 0, count: grayscale.width*grayscale.height))
        
        var Max = Image<Float>(width: grayscale.width,height:grayscale.height, pixels: [Float](repeating: 0.0, count: grayscale.width*grayscale.height))
        
        
        var xSobel = Image<Int>(width: 3, height: 3, pixels: [-1,  0,  1,  -2, 0,  2,  -1, 0, 1])
        var ySobel = Image<Int>(width: 3, height: 3, pixels: [-1,  -2,  -1,  0, 0,  0,  1, 2, 1])
        
        
        Iy = grayscale.convoluted(with: ySobel)

        Iy = grayscale.convoluted(with: ySobel)

        for i in 0...grayscale.width-1
        {
            for j in 0...grayscale.height-1
            {
                if (i==0 || i == grayscale.width-1 || j == 0 || j == grayscale.height-1)
                {
                    G2[i,j] = blurred[i,j]
                    Dx[i,j] = 0.0
                }
                else
                {
                    G2[i,j] = sqrtf(powf(0.5*Ix[i,j], 2.0) + powf(0.5*Iy[i,j], 2.0))
                    Dx[i,j] = atan(Iy[i,j]/Ix[i,j])*180/Float.pi
                }
                
            }
        }
        
        var highThreshold = G2.max()! * 0.55;
        var lowThreshold = G2.max()! * 0.05;
        
        for i in 1...grayscale.width-2
        {
            for j in 1...grayscale.height-2
            {
                var previousIntensity = Float(0.0)
                var nextIntensity = Float(0.0)
                
                if (Dx[i,j] >= 0 && Dx[i,j] < 22.5) || (Dx[i,j] >= 157.5 && Dx[i,j] < 180.0)
                {
                    previousIntensity = G2[i,j-1]
                    nextIntensity = G2[i,j+1]
                }
                else if Dx[i,j] >= 22.5 && Dx[i,j] < 67.5
                {
                    previousIntensity = G2[i-1,j+1]
                    nextIntensity = G2[i+1,j-1]
                }
                else if Dx[i,j] >= 67.5 && Dx[i,j] < 112.5
                {
                    previousIntensity = G2[i-1,j]
                    nextIntensity = G2[i+1,j+1]
                }
                else if Dx[i,j] >= 112.5 && Dx[i,j] < 157.5
                {
                    previousIntensity = G2[i-1,j-1]
                    nextIntensity = G2[i+1,j+1]
                }
                
                if G2[i,j] >= nextIntensity && G2[i,j] >= previousIntensity
                {
                    Max[i,j] = G2[i,j]
                    
                    if Max[i,j] >= highThreshold
                    {
                        C[i,j] = 255
                    }
                    else if Max[i,j] < lowThreshold
                    {
                        C[i,j] = 0
                    }
                }
                else
                {
                    Max[i,j] = 0.0
                    C[i,j] = 0
                }
                
            }
        }
        
        for i in 1...grayscale.width-2
        {
            for j in 1...grayscale.height-2
            {
                if Max[i,j] >= lowThreshold && Max[i,j] < highThreshold
                {
                    if C[i-1,j-1] == 255 || C[i,j-1] == 255 || C[i+1,j-1] == 255
                       || C[i-1,j] == 255 || C[i+1,j] == 255 || C[i-1,j+1] == 255
                       || C[i,j+1] == 255 || C[i+1,j+1] == 255
                    {
                        C[i,j] = 255
                    }
                }
            }
        }
        
        for i in 0...grayscale.width-1
        {
            for j in 0...grayscale.height-1
            {
                if C[i,j] == 255
                {
                     image[i,j] = RGBA(red: 255, green: 255, blue: 255, alpha: 255)
                }
                else
                {
                     image[i,j] = RGBA(red: 0, green: 0, blue: 0, alpha: 255)
                }
            }
        }
    
        return image
       
    }
    
}

// Set up the view, gesture recongizers, pulse effects for the view segmentation button.
extension SegmentationAlertView
{
    func setupImageView()
    {
        segmentationImageView.backgroundColor = UIColor.white
        segmentationImageView.isUserInteractionEnabled = true
        
           
        segmentationImageView.frame = CGRect(x: 5, y: self.currentHeight, width: self.width - 10, height: UIScreen.main.bounds.height/2 - 15)
        segmentationImageView.layer.cornerRadius = 6
        segmentationImageView.contentMode = .scaleAspectFit
        segmentationImageView.image = self.previousFiltered.last
        
        segmentationImageView2.frame = CGRect(x: 5, y: self.currentHeight, width: 1080, height: 1160)
        segmentationImageView2.contentMode  = .scaleToFill
        segmentationImageView2.image = self.initialSegmentedImageMask?.uiImage
        
        segmentationImageView3.frame = CGRect(x: 5, y: self.currentHeight, width: self.width - 10, height: UIScreen.main.bounds.height/2 - 15)
        segmentationImageView3.contentMode  = .scaleToFill
        segmentationImageView3.image = self.initialSegmentedImageMask?.uiImage
        
        
        let longPressGestureRecognizer1 = UILongPressGestureRecognizer(target: self, action: #selector(maskSelection))
        longPressGestureRecognizer1.minimumPressDuration = 1
        segmentationImageView.isUserInteractionEnabled = true
        segmentationImageView.addGestureRecognizer(longPressGestureRecognizer1)
        
        
        let pulseImageView = UIImageView(frame: CGRect(x: self.width - 80, y:
            self.segmentationImageView.frame.height - 80, width: 55, height: 55))
                  pulseImageView.backgroundColor = .white
        pulseImageView.layer.cornerRadius = pulseImageView.frame.width/2
        pulseImageView.image = UIImage(named: "segmentedIcon")
       
        let pulseAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        pulseAnimation.duration = 1
        pulseAnimation.fromValue = 0
        pulseAnimation.toValue = 0.7
      
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .greatestFiniteMagnitude
        
        pulseImageView.layer.add(pulseAnimation, forKey: "animateOpacity")
        segmentationImageView.addSubview(pulseImageView)
        segmentationImageView.bringSubviewToFront(pulseImageView)
        
        let longPressGestureRecognizer2 = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        longPressGestureRecognizer2.minimumPressDuration = 0.5
        pulseImageView.isUserInteractionEnabled = true
        pulseImageView.addGestureRecognizer(longPressGestureRecognizer2)

        dialogView.addSubview(segmentationImageView)
        
        
    }
    
    // Set up the filter buttons actions and aspects.
    func setupFilterButtons()
    {
        let view1 = UIView(frame: CGRect(x: width/24, y: self.currentHeight , width: width/6, height: width/6))
        let filter1Button = UIButton()
        filter1Button.frame = CGRect(x: 0, y: 0 , width: view1.frame.width, height: view1.frame.height)
           filter1Button.setBackgroundImage(UIImage(named: "Chrome"), for: .normal)
           filter1Button.clipsToBounds = true
           filter1Button.tag = 0
           filter1Button.imageView?.clipsToBounds = true
           filter1Button.layer.cornerRadius = filter1Button.frame.width/2
           filter1Button.addTarget(self, action: #selector(filter1), for: .touchUpInside)

        let number1 = UILabel(frame: CGRect(x:view1.frame.width-20,y:view1.frame.height-20,width:20,height:20))
        number1.text = "1"
        number1.textColor = .white
        number1.textAlignment = .center
        number1.clipsToBounds = true
        number1.isHidden = true
        number1.layer.cornerRadius = number1.frame.width/2
        number1.backgroundColor = .red
        
        
        view1.addSubview(filter1Button)
        view1.addSubview(number1)
        view1.bringSubviewToFront(filter1Button)
        view1.bringSubviewToFront(number1)
        
        buttonViews.append(view1)
        dialogView.addSubview(view1)
        
        
        
        let filter1Label = UILabel()
        filter1Label.frame = CGRect(x: width/24, y: self.currentHeight + width/6 + 10 , width: width/6, height: 20)
        filter1Label.text = "Chrome"
        filter1Label.textColor = .black
        filter1Label.textAlignment = .center
        filter1Label.font = UIFont(name: "AvenirNextCondensed-Bold", size: 15)
        dialogView.addSubview(filter1Label)
        
        // 2
        let view2 = UIView(frame:CGRect(x: width/4 + width/24, y: self.currentHeight , width: width/6, height: width/6))
           let filter2Button = UIButton()
        filter2Button.frame = CGRect(x: 0, y: 0 , width: view2.frame.width, height: view2.frame.height)
           filter2Button.setBackgroundImage(UIImage(named: "Fade"), for: .normal)
           filter2Button.clipsToBounds = true
           filter2Button.imageView?.clipsToBounds = true
           filter2Button.layer.cornerRadius = filter1Button.frame.width/2
           filter2Button.addTarget(self, action: #selector(filter2), for: .touchUpInside)
        
        let number2 = UILabel(frame: CGRect(x:view2.frame.width-20,y:view2.frame.height-20,width:20,height:20))
        number2.text = "1"
        number2.textColor = .white
        number2.textAlignment = .center
        number2.clipsToBounds = true
        number2.isHidden = true
        number2.layer.cornerRadius = number1.frame.width/2
        number2.backgroundColor = .red
        
        view2.addSubview(filter2Button)
        view2.addSubview(number2)
        view2.bringSubviewToFront(filter2Button)
        view2.bringSubviewToFront(number2)
               
        buttonViews.append(view2)
        dialogView.addSubview(view2)
        
        let filter2Label = UILabel()
        filter2Label.frame = CGRect(x: width/4 + width/24, y: self.currentHeight + width/6 + 10, width: width/6, height: 20)
           filter2Label.text = "Fade"
           filter2Label.textColor = .black
           filter2Label.textAlignment = .center
           filter2Label.font = UIFont(name: "AvenirNextCondensed-Bold", size: 15)
           dialogView.addSubview(filter2Label)
        
        // 3
        
         let view3 = UIView(frame:  CGRect(x: width/2 + width/24, y: self.currentHeight , width: width/6, height: width/6))
           let filter3Button = UIButton()
        filter3Button.frame = CGRect(x: 0, y: 0 , width: view3.frame.width, height: view3.frame.height)
           filter3Button.setBackgroundImage(UIImage(named: "Instant"), for: .normal)
           filter3Button.clipsToBounds = true
           filter3Button.imageView?.clipsToBounds = true
           filter3Button.layer.cornerRadius = filter1Button.frame.width/2
           filter3Button.addTarget(self, action: #selector(filter3), for: .touchUpInside)
        
          let number3 = UILabel(frame: CGRect(x:view3.frame.width-20,y:view3.frame.height-20,width:20,height:20))
          number3.text = "1"
          number3.textColor = .white
          number3.textAlignment = .center
          number3.clipsToBounds = true
          number3.isHidden = true
          number3.layer.cornerRadius = number3.frame.width/2
          number3.backgroundColor = .red
          
          view3.addSubview(filter3Button)
          view3.addSubview(number3)
          view3.bringSubviewToFront(filter3Button)
          view3.bringSubviewToFront(number3)
                 
          buttonViews.append(view3)
          dialogView.addSubview(view3)
        
           let filter3Label = UILabel()
        filter3Label.frame = CGRect(x: width/2 + width/24, y: self.currentHeight + width/6 + 10 , width: width/6, height: 20)
           filter3Label.text = "Instant"
           filter3Label.textColor = .black
           filter3Label.textAlignment = .center
           filter3Label.font = UIFont(name: "AvenirNextCondensed-Bold", size: 15)
           dialogView.addSubview(filter3Label)
        
        // 4
        let view4 = UIView(frame:  CGRect(x: width * 3/4 + width/24, y: self.currentHeight , width: width/6, height: width/6))
           let filter4Button = UIButton()
           filter4Button.frame = CGRect(x: 0, y: 0 , width: view4.frame.width, height: view4.frame.height)
           filter4Button.setBackgroundImage(UIImage(named: "Tonal"), for: .normal)
           filter4Button.clipsToBounds = true
           filter4Button.imageView?.clipsToBounds = true
           filter4Button.layer.cornerRadius = filter1Button.frame.width/2
           filter4Button.addTarget(self, action: #selector(filter4), for: .touchUpInside)
           
         let number4 = UILabel(frame: CGRect(x:view4.frame.width-20,y:view4.frame.height-20,width:20,height:20))
               number4.text = "1"
               number4.textColor = .white
               number4.textAlignment = .center
               number4.clipsToBounds = true
               number4.isHidden = true
               number4.layer.cornerRadius = number4.frame.width/2
               number4.backgroundColor = .red
               
               view4.addSubview(filter4Button)
               view4.addSubview(number4)
               view4.bringSubviewToFront(filter4Button)
               view4.bringSubviewToFront(number4)
                      
               buttonViews.append(view4)
               dialogView.addSubview(view4)
        
           let filter4Label = UILabel()
        filter4Label.frame = CGRect(x: width * 3/4 + width/24, y: self.currentHeight + width/6 + 10 , width: width/6, height: 20)
           filter4Label.text = "Tonal"
           filter4Label.textColor = .black
           filter4Label.textAlignment = .center
           filter4Label.font = UIFont(name: "AvenirNextCondensed-Bold", size: 15)
           dialogView.addSubview(filter4Label)
        
        // 5
        
          self.currentHeight += width/6 + 20 + 20
        
        let view5 = UIView(frame:  CGRect(x: width/24, y: self.currentHeight , width: width/6, height: width/6))
              let filter5Button = UIButton()
         filter5Button.frame = CGRect(x: 0, y: 0 , width: view5.frame.width, height: view5.frame.height)
              filter5Button.backgroundColor = .white
              filter5Button.setBackgroundImage(UIImage(named: "Mono"), for: .normal)
              filter5Button.clipsToBounds = true
              filter5Button.imageView?.clipsToBounds = true
              filter5Button.layer.cornerRadius = filter1Button.frame.width/2
              filter5Button.addTarget(self, action: #selector(filter5), for: .touchUpInside)
             
           let number5 = UILabel(frame: CGRect(x:view5.frame.width-20,y:view5.frame.height-20,width:20,height:20))
            number5.text = "1"
            number5.textColor = .white
            number5.textAlignment = .center
            number5.clipsToBounds = true
            number5.isHidden = true
            number5.layer.cornerRadius = number5.frame.width/2
            number5.backgroundColor = .red
                         
            view5.addSubview(filter5Button)
            view5.addSubview(number5)
            view5.bringSubviewToFront(filter5Button)
            view5.bringSubviewToFront(number5)
                                
            buttonViews.append(view5)
            dialogView.addSubview(view5)
        
              let filter5Label = UILabel()
        filter5Label.frame = CGRect(x: width/24, y: self.currentHeight + width/6 + 10 , width: width/6, height: 20)
              filter5Label.text = "Mono"
              filter5Label.textColor = .black
              filter5Label.textAlignment = .center
              filter5Label.font = UIFont(name: "AvenirNextCondensed-Bold", size: 15)
              dialogView.addSubview(filter5Label)
              
              //  6
            let view6 = UIView(frame:  CGRect(x: width/4 + width/24, y: self.currentHeight , width: width/6, height: width/6))
        
              let filter6Button = UIButton()
              filter6Button.frame =  CGRect(x: 0, y: 0 , width: view6.frame.width, height: view6.frame.height)
              filter6Button.backgroundColor = .white
              filter6Button.setBackgroundImage(UIImage(named: "Noir"), for: .normal)
              filter6Button.clipsToBounds = true
              filter6Button.imageView?.clipsToBounds = true
              filter6Button.layer.cornerRadius = filter1Button.frame.width/2
              filter6Button.addTarget(self, action: #selector(filter6), for: .touchUpInside)
             
            let number6 = UILabel(frame: CGRect(x:view6.frame.width-20,y:view6.frame.height-20,width:20,height:20))
            number6.text = "1"
            number6.textColor = .white
            number6.textAlignment = .center
            number6.clipsToBounds = true
            number6.isHidden = true
            number6.layer.cornerRadius = number6.frame.width/2
            number6.backgroundColor = .red
                                      
            view6.addSubview(filter6Button)
            view6.addSubview(number6)
            view6.bringSubviewToFront(filter6Button)
            view6.bringSubviewToFront(number6)
                                             
            buttonViews.append(view6)
            dialogView.addSubview(view6)
        
              let filter6Label = UILabel()
        filter6Label.frame = CGRect(x: width/4 + width/24, y: self.currentHeight + width/6 + 10, width: width/6, height: 20)
              filter6Label.text = "Noir"
              filter6Label.textColor = .black
              filter6Label.textAlignment = .center
              filter6Label.font = UIFont(name: "AvenirNextCondensed-Bold", size: 15)
              dialogView.addSubview(filter6Label)
        
           // 7
        
           let view7 = UIView(frame:  CGRect(x: width/2 + width/24, y: self.currentHeight , width: width/6, height: width/6))
              let filter7Button = UIButton()
              filter7Button.frame =  CGRect(x: 0, y: 0 , width: view7.frame.width, height: view7.frame.height)
              filter7Button.backgroundColor = .white
              filter7Button.setBackgroundImage(UIImage(named: "Process"), for: .normal)
              filter7Button.clipsToBounds = true
              filter7Button.imageView?.clipsToBounds = true
              filter7Button.layer.cornerRadius = filter1Button.frame.width/2
              filter7Button.addTarget(self, action: #selector(filter7), for: .touchUpInside)

            let number7 = UILabel(frame: CGRect(x:view7.frame.width-20,y:view7.frame.height-20,width:20,height:20))
            number7.text = "1"
            number7.textColor = .white
            number7.textAlignment = .center
            number7.clipsToBounds = true
            number7.isHidden = true
            number7.layer.cornerRadius = number6.frame.width/2
            number7.backgroundColor = .red
                                  
            view7.addSubview(filter7Button)
            view7.addSubview(number7)
            view7.bringSubviewToFront(filter7Button)
            view7.bringSubviewToFront(number7)
                                         
            buttonViews.append(view7)
            dialogView.addSubview(view7)
        
           
              let filter7Label = UILabel()
        filter7Label.frame = CGRect(x: width/2 + width/24, y: self.currentHeight + width/6 + 10 , width: width/6, height: 20)
              filter7Label.text = "Process"
              filter7Label.textColor = .black
              filter7Label.textAlignment = .center
              filter7Label.font = UIFont(name: "AvenirNextCondensed-Bold", size: 15)
              dialogView.addSubview(filter7Label)
           
                // 8
        
              let view8 = UIView(frame:  CGRect(x: width * 3/4 + width/24, y: self.currentHeight , width: width/6, height: width/6))
        
              let filter8Button = UIButton()
              filter8Button.frame = CGRect(x: 0, y: 0 , width: view8.frame.width, height: view8.frame.height)
              filter8Button.setBackgroundImage(UIImage(named: "Transfer"), for: .normal)
              filter8Button.clipsToBounds = true
              filter8Button.imageView?.clipsToBounds = true
              filter8Button.layer.cornerRadius = filter1Button.frame.width/2
              filter8Button.addTarget(self, action: #selector(filter8), for: .touchUpInside)
              
            let number8 = UILabel(frame: CGRect(x:view8.frame.width-20,y:view8.frame.height-20,width:20,height:20))
                   number8.text = "1"
                   number8.textColor = .white
                   number8.textAlignment = .center
                   number8.clipsToBounds = true
                   number8.isHidden = true
                   number8.layer.cornerRadius = number8.frame.width/2
                   number8.backgroundColor = .red
                                         
                   view8.addSubview(filter8Button)
                   view8.addSubview(number8)
                   view8.bringSubviewToFront(filter8Button)
                   view8.bringSubviewToFront(number8)
                                                
                   buttonViews.append(view8)
                   dialogView.addSubview(view8)
           
             let filter8Label = UILabel()
              filter8Label.frame = CGRect(x: width * 3/4 + width/24, y: self.currentHeight + width/6 + 10 , width: width/6, height: 20)
              filter8Label.text = "Transfer"
              filter8Label.textColor = .black
              filter8Label.textAlignment = .center
              filter8Label.font = UIFont(name: "AvenirNextCondensed-Bold", size: 15)
              dialogView.addSubview(filter8Label)
        
             self.currentHeight += width/6 + 20 + 20
        
             let view9 = UIView(frame:  CGRect(x:  width/24, y: self.currentHeight , width: width/6, height: width/6))
            
            let filter9Button = UIButton()
            filter9Button.frame = CGRect(x: 0, y: 0 , width: view9.frame.width, height: view9.frame.height)
            filter9Button.setBackgroundImage(UIImage(named: "Canny"), for: .normal)
            filter9Button.clipsToBounds = true
            filter9Button.imageView?.clipsToBounds = true
            filter9Button.layer.cornerRadius = filter1Button.frame.width/2
            filter9Button.addTarget(self, action: #selector(filter9), for: .touchUpInside)
                     
            let number9 = UILabel(frame: CGRect(x:view9.frame.width-20,y:view8.frame.height-20,width:20,height:20))
            number9.text = "1"
            number9.textColor = .white
            number9.textAlignment = .center
            number9.clipsToBounds = true
            number9.isHidden = true
            number9.layer.cornerRadius = number9.frame.width/2
            number9.backgroundColor = .red
                                                
            view9.addSubview(filter9Button)
            view9.addSubview(number9)
            view9.bringSubviewToFront(filter9Button)
            view9.bringSubviewToFront(number9)
                                                       
            buttonViews.append(view9)
            dialogView.addSubview(view9)
                  
            let filter9Label = UILabel()
            filter9Label.frame = CGRect(x: width/24, y: self.currentHeight + width/6 + 10 , width: width/6, height: 20)
            filter9Label.text = "Canny"
            filter9Label.textColor = .black
            filter9Label.textAlignment = .center
            filter9Label.font = UIFont(name: "AvenirNextCondensed-Bold", size: 15)
            dialogView.addSubview(filter9Label)
        
         let view10 = UIView(frame:  CGRect(x: width/4 + width/24, y: self.currentHeight , width: width/6, height: width/6))
                   
         let filter10Button = UIButton()
        filter10Button.frame = CGRect(x: 0, y: 0 , width: view10.frame.width, height: view10.frame.height)
        filter10Button.setBackgroundImage(UIImage(named: "Blur"), for: .normal)
        filter10Button.clipsToBounds = true
        filter10Button.imageView?.clipsToBounds = true
        filter10Button.layer.cornerRadius = filter1Button.frame.width/2
        filter10Button.addTarget(self, action: #selector(filter10), for: .touchUpInside)
                            
        let number10 = UILabel(frame: CGRect(x:view10.frame.width-20,y:view8.frame.height-20,width:20,height:20))
        number10.text = "1"
        number10.textColor = .white
        number10.textAlignment = .center
        number10.clipsToBounds = true
        number10.isHidden = true
        number10.layer.cornerRadius = number10.frame.width/2
        number10.backgroundColor = .red
                                                       
        view10.addSubview(filter10Button)
        view10.addSubview(number10)
        view10.bringSubviewToFront(filter10Button)
        view10.bringSubviewToFront(number10)
                                                              
        buttonViews.append(view10)
        dialogView.addSubview(view10)
                         
        let filter10Label = UILabel()
        filter10Label.frame = CGRect(x: width/4 + width/24, y: self.currentHeight + width/6 + 10 , width: width/6, height: 20)
        filter10Label.text = "Blur"
        filter10Label.textColor = .black
        filter10Label.textAlignment = .center
        filter10Label.font = UIFont(name: "AvenirNextCondensed-Bold", size: 15)
        dialogView.addSubview(filter10Label)
      
        let view11 = UIView(frame:  CGRect(x: width/2 + width/24, y: self.currentHeight , width: width/6, height: width/6))
                   
         let filter11Button = UIButton()
        filter11Button.frame = CGRect(x: 0, y: 0 , width: view11.frame.width, height: view11.frame.height)
        filter11Button.setBackgroundImage(UIImage(named: "Sharpen"), for: .normal)
        filter11Button.clipsToBounds = true
        filter11Button.imageView?.clipsToBounds = true
        filter11Button.layer.cornerRadius = filter1Button.frame.width/2
        filter11Button.addTarget(self, action: #selector(filter11), for: .touchUpInside)
                            
        let number11 = UILabel(frame: CGRect(x:view11.frame.width-20,y:view11.frame.height-20,width:20,height:20))
        number11.text = "1"
        number11.textColor = .white
        number11.textAlignment = .center
        number11.clipsToBounds = true
        number11.isHidden = true
        number11.layer.cornerRadius = number11.frame.width/2
        number11.backgroundColor = .red
                                                       
        view11.addSubview(filter11Button)
        view11.addSubview(number11)
        view11.bringSubviewToFront(filter11Button)
        view11.bringSubviewToFront(number11)
                                                              
        buttonViews.append(view11)
        dialogView.addSubview(view11)
                         
        let filter11Label = UILabel()
        filter11Label.frame = CGRect(x: width/2 + width/24, y: self.currentHeight + width/6 + 10 , width: width/6, height: 20)
        filter11Label.text = "Sharpen"
        filter11Label.textColor = .black
        filter11Label.textAlignment = .center
        filter11Label.font = UIFont(name: "AvenirNextCondensed-Bold", size: 15)
        dialogView.addSubview(filter11Label)
        
        
        let resetButton = UIButton()
        resetButton.frame = CGRect(x: 3*width/4 + 25, y: self.currentHeight + 10  , width: 50, height: 30)
        resetButton.backgroundColor = .white
        resetButton.setTitle("Reset", for: .normal)
        resetButton.setTitleColor(.black, for: .normal)
        resetButton.titleLabel?.textAlignment = .center
        resetButton.titleLabel?.textColor = .black
        resetButton.titleLabel?.font = UIFont(name: "AvenirNextCondensed-Bold", size: 18)
        resetButton.layer.borderColor = UIColor.black.cgColor
        resetButton.layer.borderWidth = 1
        resetButton.layer.cornerRadius = CGFloat(5)
        resetButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
        dialogView.addSubview(resetButton)
        
        
        let saveButton = UIButton()
        saveButton.frame = CGRect(x: 3*width/4 + 25 , y: self.currentHeight + 50 , width: 50, height: 30)
        saveButton.backgroundColor = .white
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.black, for: .normal)
        saveButton.titleLabel?.textAlignment = .center
        saveButton.titleLabel?.font = UIFont(name: "AvenirNextCondensed-Bold", size: 18)
         saveButton.layer.borderColor = UIColor.black.cgColor
        saveButton.layer.cornerRadius = CGFloat(5)
         saveButton.layer.borderWidth = 1
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        dialogView.addSubview(saveButton)
        
        self.currentHeight +=  width/6 + 60
        
        //self.currentHeight += 20 + 20 + 20
        
        
        
       }
       
}

