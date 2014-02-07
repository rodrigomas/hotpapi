//
//  NSURLRequest+IgnoreSSL.m
//  DCAPID
//
//  Created by Rodrigo Marques on 1/12/14.
//  Copyright (c) 2014 Ande Tecnologia. All rights reserved.
//

#import "NSURLRequest+IgnoreSSL.h"

@implementation NSURLRequest (IgnoreSSL)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host
{
    return YES;
    /*
    // ignore certificate errors only for this domain
    if ([host hasSuffix:@"andedcserver.cloudapp.net"])
    {
        return YES;
    }
    else
    {
        return NO;
    }*/
}
@end
