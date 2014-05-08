//
//  EVViewController.h
//  Eval
//
//  Created by Willy Blandin on 28/05/2013.
//  Copyright (c) 2013 Wit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EVViewController : UIViewController <WitDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>
@property (strong) IBOutlet UITextField* instanceName;
@property (strong) IBOutlet UITextField* instanceToken;
@end
