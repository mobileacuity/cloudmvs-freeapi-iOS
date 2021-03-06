//
//  URLConnection.h
//  SimpleOverlay
//
//  Created by Aleksander Niedziolko on 02/11/2012.
//
//  Copyright (c) 2013 Mobile Acuity Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

typedef void (^URLConnectionCompletionBlock)        (NSData *data);
typedef void (^URLConnectionNotFoundBlock)          (void);
typedef void (^URLConnectioErrorBlock)              (NSError *error);
typedef void (^URLConnectioDataReceivedBlock)       (NSData *data);


@interface URLConnection : NSObject <NSURLConnectionDelegate>

+(id)asyncConnectionWithRequest:(NSURLRequest *)request
                   completionBlock:(URLConnectionCompletionBlock)completionBlock
                        errorBlock:(URLConnectioErrorBlock)errorBlock
                            notFoundBlock:(URLConnectionNotFoundBlock)notFoundBlock
                                dataBlock:(URLConnectioDataReceivedBlock)dataBlock;


-(void)close;

@end
