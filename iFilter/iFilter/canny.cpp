#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

#include <iostream>
#include <queue>
#include <math.h>

using namespace cv;
using namespace std;

#define PI 3.14159265

// Step 1: complete gradient and threshold
// Step 2: complete sobel
// Step 3: complete canny (recommended substep: return Max instead of C to check it) 

// Raw gradient. No denoising

void gradient(const Mat&Ic, Mat& G2)
{
	Mat I;
	cvtColor(Ic, I, COLOR_BGR2GRAY);
    
	int m = I.rows, n = I.cols;
	G2 = Mat(m, n, CV_32F);

	for (int i = 0; i < m; i++)
    {
		for (int j = 0; j < n; j++)
        {
           
            if ( i == 0 || i == m-1 || j == 0 || j == n-1)
            {
                G2.at<float>(i,j) = float(I.at<uchar>(i,j));
            }
            else
            {
                
                float Ix = float(0.5 * (I.at<uchar>(i+1,j)-I.at<uchar>(i-1,j)));
                float Iy = float(0.5 * (I.at<uchar>(i,j+1)-I.at<uchar>(i,j-1)));
                G2.at<float>(i,j) = float(sqrt(pow(Ix,2.0) + pow(Iy,2.0)));
            }
        }
        
    }
}


// Gradient (and derivatives), Sobel denoising
void sobel(const Mat&Ic, Mat& Ix, Mat& Iy, Mat& G2, Mat& Dx)
{
	Mat I;
	cvtColor(Ic, I, COLOR_BGR2GRAY);
    int m = I.rows, n = I.cols;
    
    float gaussian[9] = { 1, 2, 1, 2, 4, 2, 1, 2, 1 };
    Mat gaussianKernel = Mat(3, 3, CV_32F, gaussian)/16.0;
    filter2D(I, I, -1, gaussianKernel,cv::Point(-1,-1),0.0,BORDER_REPLICATE);
  
	Ix = Mat(m, n, CV_32F);
	Iy = Mat(m, n, CV_32F);
	G2 = Mat(m, n, CV_32F);
    Dx = Mat(m, n, CV_32F);
    
    float x[9] = { -1, 0, 1, -2, 0, 2, -1, 0, 1 };
    Mat kernelx = Mat(3, 3, CV_32F, x);
   
    float y[9] = { -1, -2, -1, 0, 0, 0, 1, 2, 1 };
    Mat kernely = Mat(3,3,CV_32F,y);
    
    
    filter2D(I, Ix, -1, kernelx,cv::Point(-1,-1),0.0,BORDER_REPLICATE);
    filter2D(I, Iy, -1, kernely,cv::Point(-1,-1),0.0,BORDER_REPLICATE);
    

	for (int i = 0; i < m; i++)
    {
		for (int j = 0; j < n; j++)
        {
            
            if ( i == 0 || i == m-1 || j == 0 || j == n-1)
            {
                G2.at<float>(i,j) = float(I.at<uchar>(i,j));
                Dx.at<float>(i,j) = 0.0;
            }
            else
            {
                
                G2.at<float>(i,j) = float(sqrt(pow(0.5*float(Ix.at<uchar>(i,j)),2.0) + pow(0.5*float(Iy.at<uchar>(i,j)),2.0)));
                
                Dx.at<float>(i,j) = atan(float(Iy.at<uchar>(i,j))/float(Ix.at<uchar>(i,j)))*180/PI;
                
            }
            
		}
	}
    
    //std::cout<<G2<<std::endl;
    //std::cout<<Dx<<std::endl;
}

// Gradient thresholding, default = do not denoise
Mat threshold(const Mat& Ic, float s, bool denoise = false)
{
	Mat Ix, Iy, G2, Dx;
	if (denoise)
		sobel(Ic, Ix, Iy, G2, Dx);
	else
		gradient(Ic, G2);
	int m = Ic.rows, n = Ic.cols;
	Mat C(m, n, CV_8U);
	for (int i = 0; i < m; i++)
		for (int j = 0; j < n; j++)
            
            if ( G2.at<float>(i,j) >= s)
            {
                C.at<uchar>(i,j) = 255;
            }
            else
            {
                C.at<uchar>(i,j) = 0;
            }
	return C;
}

// Canny edge detector
Mat canny(const Mat& Ic, float s1)
{
	Mat Ix, Iy, G2, Dx;
	sobel(Ic, Ix, Iy, G2, Dx);
    
	int m = Ic.rows, n = Ic.cols;
	Mat Max(m, n, CV_8U);
    
    Mat C(m, n, CV_8U);
    C.setTo(0);
    
    double highThreshold,lowThreshold;
    minMaxLoc(G2,&lowThreshold, &highThreshold);
    
    highThreshold = highThreshold * 0.25;
    lowThreshold = highThreshold * 0.05;
    
    for (int i = 0; i < m; i++)
    {
        for (int j = 0; j < n; j++)
        {
            float previousIntensity = 0.0;
            float nextIntensity = 0.0;
            
            if ((Dx.at<float>(i,j) >= 0 && Dx.at<float>(i,j) < 22.5) || (Dx.at<float>(i,j) >= 157.5 && Dx.at<float>(i,j) < 180.0))
            {
                previousIntensity = G2.at<float>(i,j-1);
                nextIntensity = G2.at<float>(i,j+1);
            }
            else if (Dx.at<float>(i,j) >= 22.5 && Dx.at<float>(i,j) < 67.5)
            {
                previousIntensity = G2.at<float>(i-1,j+1);
                nextIntensity = G2.at<float>(i+1,j-1);
                
            }
            else if (Dx.at<float>(i,j) >= 67.5 && Dx.at<float>(i,j) < 112.5)
            {
                previousIntensity = G2.at<float>(i-1,j);
                nextIntensity = G2.at<float>(i+1,j+1);
            }
            else if (Dx.at<float>(i,j) >= 112.5 && Dx.at<float>(i,j) < 157.5)
            {
                previousIntensity = G2.at<float>(i-1,j-1);
                nextIntensity = G2.at<float>(i+1,j+1);
            }
            
            if ((G2.at<float>(i,j) >= nextIntensity) && (G2.at<float>(i,j) >= previousIntensity))
            {
                Max.at<uchar>(i,j)=G2.at<float>(i,j);
                
                if (Max.at<uchar>(i,j) >= highThreshold)
                {
                    C.at<uchar>(i,j) = 255;
                }
                else if (Max.at<uchar>(i,j) < lowThreshold)
                {
                    C.at<uchar>(i,j) = 0;
                }
            }
            else
            {
                Max.at<uchar>(i,j)= 0;
                C.at<uchar>(i,j) = 0;
              
            }
        
        }
    }
    
    for (int i = 1; i < m -1 ; i++)
    {
        for (int j = 1; j < n-1; j++)
        {
            if ((Max.at<uchar>(i,j) >= lowThreshold) && (Max.at<uchar>(i,j) < highThreshold))
            {
                if (C.at<uchar>(i-1,j-1)==255 || C.at<uchar>(i,j-1)==255 || C.at<uchar>(i+1,j-1)==255
                    || C.at<uchar>(i-1,j)==255 || C.at<uchar>(i+1,j)==255 || C.at<uchar>(i-1,j+1)==255
                    || C.at<uchar>(i,j+1)==255 || C.at<uchar>(i+1,j+1)==255)
                {
                    C.at<uchar>(i,j) = 255;
                }
            }
        }
    }
    
	return C;
}

/*int main()
{
    Mat I = imread("/Users/jeremy/Desktop/LABS/INF573/TD2/road.jpg");
	imshow("Input", I);
	imshow("Threshold", threshold(I, 15));
	imshow("Threshold + denoising", threshold(I, 35, true));
	imshow("Canny", canny(I, 15));

	waitKey();

	return 0;
}
 */
