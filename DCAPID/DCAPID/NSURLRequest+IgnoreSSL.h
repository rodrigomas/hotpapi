//
//  NSURLRequest+IgnoreSSL.h
//  DCAPID
//
//  Created by Rodrigo Marques on 1/12/14.
//  Copyright (c) 2014 Ande Tecnologia. All rights reserved.
//

#ifndef DCAPID_NSURLRequest_IgnoreSSL_h
#define DCAPID_NSURLRequest_IgnoreSSL_h

@interface NSURLRequest (IgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;

@end


#endif
