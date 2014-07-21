# WitEval

Simple app to quickly test different Wit instances.

## Getting started

```
gem install cocoapods # may need sudo
pod install
```

## Update Wit iOS SDK

```
git merge --squash -s subtree --no-commit sdk
pod update
```

## Commit back to Wit iOS SDK

```
git checkout sdk
git merge --squash -s subtree --no-commit master
```
