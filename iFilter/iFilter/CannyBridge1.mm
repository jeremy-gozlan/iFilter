//
//  CannyBridge1.m
//  iFilter
//
//  Created by Jeremy on 29/11/2019.
//  Copyright © 2019 Jeremy. All rights reserved.
//


#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <Foundation/Foundation.h>
#import "iFilter-Bridging-Header.h"
#include "Canny.cpp"

@implementation CannyBridge

- (UIImage *) applyCannyIn: (UIImage *) image {
    
    // convert uiimage to mat
    cv::Mat opencvImage;
    UIImageToMat(image, opencvImage, true);
    
    // convert colorspace to the one expected by the lane detector algorithm (RGB)
    cv::Mat convertedColorSpaceImage;
    cv::cvtColor(opencvImage, convertedColorSpaceImage, COLOR_RGBA2RGB);
    
    // Run lane detection
   
    cv::Mat cannyFilteredImage = canny(convertedColorSpaceImage,0.1);
    
    // convert mat to uiimage and return it to the caller
    return MatToUIImage(cannyFilteredImage);
}

@end
