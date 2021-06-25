/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

#import "AppDelegate.h"
@import AEPCore;
@import AEPLifecycle;
@import AEPIdentity;
@import AEPServices;
@import AEPSignal;
@import AEPEdgeConsent;
@import AEPAnalytics;
@import AEPUserProfile;
@import AEPAssurance;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [AEPMobileCore setLogLevel: AEPLogLevelTrace];
    NSArray *extensionsToRegister = @[AEPMobileIdentity.class, AEPMobileLifecycle.class, AEPMobileSignal.class, AEPMobileAssurance.class, AEPMobileUserProfile.class, AEPMobileEdgeConsent.class, AEPMobileAnalytics.class];
    [AEPMobileCore registerExtensions:extensionsToRegister completion:^{
        [AEPMobileCore lifecycleStart:@{@"contextDataKey": @"contextDataVal"}];
    }];
    
    [AEPMobileCore configureWithAppId: @"94f571f308d5/e30a9514788b/launch-44fec1a705f1-development"];
    return YES;
}


#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


@end
