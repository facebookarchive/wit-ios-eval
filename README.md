# WitEval

Simple app to quickly test different Wit instances.

## Getting started

```
gem install cocoapods # may need sudo
pod install
```

If you had your project `(.xcodeproj)` open in Xcode, close it and open the `.xcworkspace` file instead. From now on, you should only use the `.xcworkspace` file.

Set your Wit Access Token in `wit-ios-eval/AppDelegate.m`

```objc
[Wit sharedInstance].accessToken = @"xxx";
```