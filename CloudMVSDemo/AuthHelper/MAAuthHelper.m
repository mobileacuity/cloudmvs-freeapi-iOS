//
//  MAAuthHelper.m
//  CloudMVSDemo
//
//  Created by Marius Ciocanel on 22/02/2013.
/*
 * Copyright (c) 2013 Mobile Acuity Ltd. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "MAAuthHelper.h"
#import <CommonCrypto/CommonCrypto.h>
#import "MF_Base64Additions.h"

#define MA_AUTH_IDENTITY @"test"
#define MA_AUTH_SECRET @"testsecret"

@interface MAAuthHelper ()
+(NSDateFormatter*)formatter;
+(NSString*)formattedStringForDate:(NSDate*)date;
@end

@implementation MAAuthHelper
//Creating this once because allocating and deallocating date formatters is an expensive operation
+(NSDateFormatter*)formatter {
	static NSDateFormatter *configuredFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		configuredFormatter = [[NSDateFormatter alloc] init];
		configuredFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z"; //RFC2822-Format
	});
	return configuredFormatter;
}

+(NSString*)formattedStringForDate:(NSDate*)date {
	return [[self formatter] stringFromDate:date];
}

+(NSMutableURLRequest*)addAuthHeadersToRequest:(NSMutableURLRequest*)unauthorisedReq {
	
	NSDate *dateNow = [NSDate date];
	DLog(@"Date now: %@",dateNow);
	DLog(@"DATE=%@",[self formattedStringForDate:dateNow]);
	
	NSString *dateString = [self formattedStringForDate:dateNow]; // This is the DATE
	NSString *requestURLString = unauthorisedReq.URL.absoluteString; // This is REQUESTURL
	DLog(@"REQUESTURL=%@",requestURLString);
	NSString *httpMethod = unauthorisedReq.HTTPMethod;
	NSString *bodyLength = [NSString stringWithFormat:@"%d",unauthorisedReq.HTTPBody.length];
	NSString *secretMessageString = [NSString stringWithFormat:@"%@%@%@%@%@",
									 MA_AUTH_IDENTITY,
									 httpMethod,
									 requestURLString,
									 dateString,
									 bodyLength];
	DLog(@"STS=%@",secretMessageString);
	NSString *token = [self hmacsha1:secretMessageString secret:MA_AUTH_SECRET];
	DLog(@"TOKEN = %@",token);
	NSString *authorizationHeader = [NSString stringWithFormat:@"MAAPIv1 %@ %@",
									 MA_AUTH_IDENTITY,
									 token];
	[unauthorisedReq setValue:authorizationHeader forHTTPHeaderField:@"Authorization"];
	[unauthorisedReq setValue:dateString forHTTPHeaderField:@"Date"];

	return unauthorisedReq;
	/*
	 IDENTITY = MA_AUTH_IDENTITY
	 SECRET = MA_AUTH_SECRET
	 DATE = Fri, 22 Feb 2013 13:12:06 +0000
	 REQUESTURL = http://demo.mobileacuity.net/auth-demo
	 STS = testidPOSThttp://demo.mobileacuity.net/auth-demoFri, 22 Feb 2013 13:12:06 +00000
	 TOKEN = NhXcd7AHLb/t7giurWLFpAUGiCY=
	 
	 
	 Format for STS = ${IDENTITY}${HTTP_METHOD}${REQUESTURL}${DATE}${BODY_LENGTH}
	 Token Generations:
	 TOKEN=$(echo -n ${STS} | openssl sha1 -hmac ${SECRET} -binary | base64)
	 
	 
	 */
}

+(NSString *)hmacsha1:(NSString *)string secret:(NSString *)key {
	
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [string cStringUsingEncoding:NSASCIIStringEncoding];
	
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
	
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
	
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
	
    NSString *hash = [HMAC base64String];
	
    return hash;
}
@end
