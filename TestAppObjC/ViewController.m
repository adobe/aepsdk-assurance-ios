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

#import "ViewController.h"
@import AEPAssurance;
@import AEPCore;
@import AEPUserProfile;
@import AEPEdgeConsent;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *assuranceVersionLabel;
@property (weak, nonatomic) IBOutlet UITextField *assuranceURLTextView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_assuranceVersionLabel setText:[NSString stringWithFormat:@"Assurance v%@",[AEPMobileAssurance extensionVersion]]];
}


- (IBAction)assuranceConnectClicked:(id)sender {
    if([_assuranceURLTextView.text isEqualToString:@""]) {
        NSLog(@"Please provide a valid Assurance session URL.");
        return;
    }
    
    [AEPMobileAssurance startSessionWithUrl:[NSURL URLWithString:_assuranceURLTextView.text]];
}

- (IBAction)trackActionClicked:(id)sender {
    [AEPMobileCore trackAction:@"Bike Purchased" data:nil];
}

- (IBAction)trackStateClicked:(id)sender {
    [AEPMobileCore trackAction:@"Home Page" data:nil];
}

- (IBAction)profileUpdateClicked:(id)sender {
    [AEPMobileUserProfile updateUserAttributesWithAttributeDict:@{@"type":@"HardCore Gamer", @"age": @16}];
}

- (IBAction)profileRemoveClicked:(id)sender {
    [AEPMobileUserProfile removeUserAttributesWithAttributeNames:@[@"age"]];
}

- (IBAction)consentUpdateYes:(id)sender {
    NSDictionary *collectConsent = @{@"collect": @{@"val": @"y"}};
    NSDictionary *currentConsents = @{@"consents": collectConsent};
    [AEPMobileEdgeConsent updateWithConsents:currentConsents];
}

- (IBAction)consentUpdateNo:(id)sender {
    NSDictionary *collectConsent = @{@"collect": @{@"val": @"n"}};
    NSDictionary *currentConsents = @{@"consents": collectConsent};
    [AEPMobileEdgeConsent updateWithConsents:currentConsents];
}

@end
