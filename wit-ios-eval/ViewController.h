//
//  ViewController.h
//  wit-ios-eval
//
//  Created by Aric Lasry on 10/21/14.
//  Copyright (c) 2014 Aric Lasry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Wit/Wit.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface ViewController : UIViewController <WitDelegate>


@end

