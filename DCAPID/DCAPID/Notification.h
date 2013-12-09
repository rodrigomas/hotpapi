//
//  Notification.h
//  DCAPI
//
//  Created by Rodrigo Marques on 11/10/13.
//  Copyright (c) 2013 Ande Tecnologia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Notification : NSObject

@property NSString *message;

@property NSDate *UTCTimeStamp;

@property NSString *title;

@property BOOL isReaded;

@property UIImage *image;

@end
