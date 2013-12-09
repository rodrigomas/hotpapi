//
//  ViewController.h
//  TestDAPI
//
//  Created by Rodrigo Marques on 11/11/13.
//  Copyright (c) 2013 Ande Tecnologia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *lbtext;
@property (strong, nonatomic) IBOutlet UIDatePicker *datep;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *lbint;

@end
