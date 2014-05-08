//
//  EVViewController.m
//  Eval
//
//  Created by Willy Blandin on 28/05/2013.
//  Copyright (c) 2013 Wit. All rights reserved.
//

#import "EVViewController.h"
#import <objc/runtime.h>

enum newInstanceState {
    HAS_NONE,
    HAS_NAME,
    HAS_TOKEN
};

@interface EVViewController ()
@property (strong) NSDictionary* cachedSettings;
@end

@implementation EVViewController {
    WITMicButton* witButton;
    UILabel* respLabel;
    UIPickerView* picker;
    UIView* pickerMechanism;
    UIView* instanceMechanism;
    NSMutableDictionary* newInstance;
    enum newInstanceState state;
}
@synthesize cachedSettings, instanceName, instanceToken;

#pragma mark - Instances management
- (NSDictionary*)settings {
    if (!cachedSettings) {
        cachedSettings = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    }

    return cachedSettings;
}

- (NSArray*)instances {
    NSArray* instances = [self settings][@"instances"];
    if (!instances) {
        return @[];
    } else {
        return instances;
    }
}

- (void)persistInstances:(NSArray*)instances {
    // add to cache
    NSMutableDictionary* settings = [[self settings] mutableCopy];
    settings[@"instances"] = instances;
    self.cachedSettings = [NSDictionary dictionaryWithDictionary:settings];

    // add to persistent storage
    [[NSUserDefaults standardUserDefaults] setObject:instances forKey:@"instances"];
}

- (NSArray*)removeInstanceByName:(NSString*)name {
    NSArray* instances = [self instances];

    NSPredicate* pred = [NSPredicate predicateWithBlock:^BOOL(NSDictionary* evaluatedObject, NSDictionary *bindings) {
        return evaluatedObject[@"name"] == name;
    }];

    NSArray* newInstances = [instances filteredArrayUsingPredicate:pred];
    [self persistInstances:newInstances];

    return instances;
}

- (NSArray*)addInstance:(NSString*)name withToken:(NSString*)token {
    NSArray* instances = [self instances];
    NSDictionary* x = @{@"name": name, @"token": token};
    instances = [instances arrayByAddingObject:x];

    [self persistInstances:instances];

    return instances;
}

- (void)doAddInstance:(NSString*)name withToken:(NSString*)token {
    state = HAS_NONE;
    [self addInstance:name withToken:token];

    [picker reloadAllComponents];
    instanceName.alpha = 0.0;
    instanceName.text = @"";
    instanceToken.alpha = 0.0;
    instanceToken.text = @"";
}

#pragma mark - WitDelegate
NSString* kv(NSString* key, NSString* value) {
    return [NSString stringWithFormat:@"%@ = %@", key, value];
}

- (void)witDidGraspIntent:(NSString *)intent entities:(NSDictionary *)entities body:(NSString *)body error:(NSError *)e {
    if (e) {
        debug(@"WitError, %@", e.localizedDescription);
        [self slideUpWithBody:[@[e.localizedDescription] componentsJoinedByString:@"\n"]];
        return;
    }

    NSMutableString* message = [NSMutableString stringWithFormat:@"%@\n%@\n", kv(@"intent", intent), kv(@"body", body)];

    [entities enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [message appendFormat:@"%@\n", kv(key, obj)];
    }];

    [self slideUpWithBody:message];
}

- (void)setWitInfos:(NSString*)token {
    [Wit sharedInstance].accessToken = token;
}

#pragma mark - Animations
- (void)slideUpWithBody:(NSString*)body {
    CGFloat bodyMarginTop = 20.0f;
    CGFloat micMarginTop = 10.0f;
    CGFloat lblMarginLR = 10.0f;

    [UIView animateWithDuration:0.85f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect f = witButton.frame;
        f.origin.y = bodyMarginTop;
        witButton.frame = f;
    } completion:^(BOOL finished) {
        CGFloat micH = witButton.frame.size.height;
        CGFloat lblY = micH + bodyMarginTop + micMarginTop;
        respLabel.text = body;
        respLabel.frame = CGRectMake(lblMarginLR,
                                     lblY,
                                     [UIScreen mainScreen].bounds.size.width - lblMarginLR*2,
                                     [UIScreen mainScreen].bounds.size.height - lblY);

        [respLabel sizeToFit];
    }];
}

#pragma mark - UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSDictionary* selected = [self instances][row];
    [self setWitInfos:selected[@"token"]];
    debug(@"Selected %@", selected[@"name"]);
    [UIView animateWithDuration:0.6f animations:^{
        picker.alpha = 0.0;
    }];
}

#pragma mark - UIPickerDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component > 0) {
        debug(@"wtf");
        return -1;
    }
    return [[self instances] count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self instances][row][@"name"];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSString* val = textField.text;
    debug(@"val = \"%@\"", val);

    if ([val length] == 0) {
        return;
    }

    if (textField == instanceName) {
        if (state == HAS_TOKEN) {
            // finish
            [self doAddInstance:val withToken:newInstance[@"token"]];
        } else {
            newInstance[@"name"] = val;
            state = HAS_NAME;
        }

        return;
    }

    if (textField == instanceToken) {
        if (state != HAS_NAME) {
            state = HAS_TOKEN;
            newInstance[@"token"] = val;
            [instanceName becomeFirstResponder];
        } else {
            // finish
            [self doAddInstance:newInstance[@"name"] withToken:val];
        }

        return;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    debug(@"should return");
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UIGestureRecognizers target
- (void)longPressed:(UILongPressGestureRecognizer*)r {
    if (r.view == pickerMechanism) {
        [UIView animateWithDuration:0.6f animations:^{
            picker.alpha = 1.0f;
        }];
    } else if (r.view == instanceMechanism) {
        [UIView animateWithDuration:0.6f animations:^{
            instanceName.alpha = 1.0f;
            instanceToken.alpha = 1.0f;
        }];
        [instanceName becomeFirstResponder];
    }
}

#pragma mark - NSNotification - UIKeyboard
void translateAbove(UIView* v, CGRect r) {
    CGFloat currentY = v.frame.origin.y;
    CGRect newRect = v.frame;
    newRect.origin.y = r.origin.y - 2*newRect.size.height;
    v.frame = newRect;
    objc_setAssociatedObject(v, @"realY", @(currentY), OBJC_ASSOCIATION_COPY);
}

void restoreY(UIView* v) {
    CGFloat realY = [objc_getAssociatedObject(v, @"realY") floatValue];
    CGRect newRect = v.frame;
    newRect.origin.y = realY;
    v.frame = newRect;
}

- (void)keyboardWillShow:(NSNotification*)notif {
    // move text field above kb
    CGRect kbRect = [notif.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

    translateAbove(instanceName, kbRect);
    translateAbove(instanceToken, kbRect);
}

- (void)keyboardWillHide:(NSNotification*)notif {
    // restore text field
    restoreY(instanceName);
    restoreY(instanceToken);
}

#pragma mark - Lifecycle
- (void)UI {
    self.view.backgroundColor = [UIColor whiteColor];

    CGRect screen = [UIScreen mainScreen].bounds;
    CGRect frame = self.view.frame;

    // speak button
    CGFloat w = 100;
    CGFloat h = 100;
    CGRect btnRect = CGRectMake(screen.size.width/2-w/2, screen.size.height/2-h/2, w, h);
    witButton = [[WITMicButton alloc] initWithFrame:btnRect];
    witButton.microphoneLayer.backgroundColor = [UIColor colorWithRed:0.50f green:0.50f blue:0.50f alpha:1.00f].CGColor;
    witButton.volumeLayer.backgroundColor = [UIColor colorWithRed:0.50f green:0.50f blue:0.50f alpha:1.00f].CGColor;
    witButton.innerCircleView.fillColor = [UIColor whiteColor];
    witButton.outerCircleView.fillColor = [UIColor colorWithRed:0.94f green:0.94f blue:0.94f alpha:0.5f];
    witButton.outerCircleView.strokeColor = [UIColor colorWithRed:0.7f green:0.7f blue:0.7f alpha:0.5f];
    witButton.alpha = 1.0;
    [self.view addSubview:witButton];

    // label
    respLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    respLabel.numberOfLines = 0;
    respLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18];
    [self.view addSubview:respLabel];

    // secret picker, bottom right
    CGFloat pickerW = screen.size.width;
    const CGFloat pickerH = 180.0f;
    CGRect pickerFrame = CGRectMake(0, screen.size.height - pickerH, pickerW, pickerH);
    picker = [[UIPickerView alloc] init];
    picker.frame = pickerFrame;
    picker.alpha = 0.0;
    picker.delegate = self;
    picker.dataSource = self;
    [self.view addSubview:picker];

    CGFloat mecH = 15;
    CGFloat mecW = 15;
    CGRect mecFrame = CGRectMake(frame.size.width-mecW, frame.size.height-mecH, mecW, mecH);
    pickerMechanism = [[UIView alloc] initWithFrame:mecFrame];
    [self.view addSubview:pickerMechanism];
    UILongPressGestureRecognizer* picLPRecog =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    [pickerMechanism addGestureRecognizer:picLPRecog];

    // secret input, bottom left
    instanceName.alpha = 0.0;
    instanceName.delegate = self;
    instanceToken.alpha = 0.0;
    instanceToken.delegate = self;

    CGRect instanceMecFrame = CGRectMake(0, frame.size.height-mecH, mecW, mecH);
    instanceMechanism = [[UIView alloc] initWithFrame:instanceMecFrame];
    [self.view addSubview:instanceMechanism];
    UILongPressGestureRecognizer* instanceLPRecog =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    [instanceMechanism addGestureRecognizer:instanceLPRecog];

    // register for keyboard events
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)initialize {
    [Wit sharedInstance].delegate = self;
    [[Wit sharedInstance] setContext:@{@"reference_time": @"2014-02-02T13:38:02.972Z"}];
    newInstance = [@{} mutableCopy];
    [self instances]; // warm up cache
    id firstInstance = [[self instances] firstObject];
    [self setWitInfos:firstInstance[@"token"]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initialize];
    [self UI];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end