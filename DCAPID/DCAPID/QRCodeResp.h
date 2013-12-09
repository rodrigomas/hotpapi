//
//  QRCodeResp.h
//  DCAPI
//
//  Created by Rodrigo Marques on 11/10/13.
//  Copyright (c) 2013 Ande Tecnologia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface QRCodeResp : NSObject

@property NSString *token;

@property int timeout;

@property int interval;

@property UIImage* image;

@end
