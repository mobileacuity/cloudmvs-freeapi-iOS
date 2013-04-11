//
//  URLConnection.m
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

#import "URLConnection.h"

@interface URLConnection () {
    BOOL failed;
    URLConnectionCompletionBlock completionBlock;
    URLConnectioErrorBlock errorBlock;
    URLConnectionNotFoundBlock notFoundBlock;
    URLConnectioDataReceivedBlock dataBlock;
}

@property (strong,nonatomic) NSURLConnection *connection;
@property (strong,nonatomic) NSURLRequest    *request;
@property (strong,nonatomic) NSMutableData   *data;

@end

@implementation URLConnection

@synthesize connection,request,data;

+ (id)asyncConnectionWithRequest:(NSURLRequest *)_request
                   completionBlock:(URLConnectionCompletionBlock)_completionBlock
                        errorBlock:(URLConnectioErrorBlock)_errorBlock
                            notFoundBlock:(URLConnectionNotFoundBlock)_notFoundBlock
                                dataBlock:(URLConnectioDataReceivedBlock)_dataBlock{
    
    URLConnection *_connection = [[URLConnection alloc] initWithRequest:_request
                                                       completionBlock:_completionBlock
                                                            errorBlock:_errorBlock
                                                                notFoundBlock:_notFoundBlock
                                                                    dataBlock:_dataBlock];
    [_connection start];
    return _connection;
}


- (id)initWithRequest:(NSURLRequest *)_request
      completionBlock:(URLConnectionCompletionBlock)_completionBlock
           errorBlock:(URLConnectioErrorBlock)_errorBlock
                notFoundBlock:(URLConnectionNotFoundBlock)_notFoundBlock
                    dataBlock:(URLConnectioDataReceivedBlock)_dataBlock{
    self = [super init];
    if (self) {
        failed = NO;
        request =           _request;
        completionBlock =   _completionBlock;
        errorBlock =        _errorBlock;
        notFoundBlock =     _notFoundBlock;
        dataBlock = _dataBlock;
    }
    return self;
}



- (void)start {
    connection = [NSURLConnection connectionWithRequest:request delegate:self];
    data = [NSMutableData data];
}


- (void)close{
    [connection cancel];
}


#pragma mark NSURLConnectionDelegate

- (void)connectionDidFinishLoading:(NSURLConnection *)_connection {
    if(failed)return;
    if(completionBlock) completionBlock(data);
}

- (void)connection:(NSURLConnection *)_connection
  didFailWithError:(NSError *)error {
    if(errorBlock) errorBlock(error);
}


- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)_data {
    if(dataBlock){
        dataBlock(_data);
    }else{
    [data appendData:_data];
    }
}


- (void) connection:(NSURLConnection *)_connection didReceiveResponse:(NSURLResponse *)response{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    int code = [httpResponse statusCode];
    if(code==400){
        if(notFoundBlock) notFoundBlock();
        failed = YES;
        return;
    }
    if(code<200 || code >299){
        DLog(@"HTTP RESPONSE: %d",code);
        [self connection:_connection didFailWithError:nil];
    }
}



@end