//
//  main.m
//  CloudMVSDemo
//
//  Created by Aleksander Niedziolko on 28/01/2013.
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

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

int main(int argc, char *argv[])
{
    // Force language of app here
    // en - English
    // es - Spanish
    // fr - French
    NSArray *langOrder = [NSArray arrayWithObjects:@"en", nil];
    [[NSUserDefaults standardUserDefaults] setObject:langOrder forKey:@"AppleLanguages"];
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
