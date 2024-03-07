#import "DisneyFreezeFix.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

/// Whether or not we should skip calls to `-[UIGestureRecognizer setEnabled]`
BOOL shouldSkipSetEnabled = NO;

@implementation DisneyFreezeFix

/// Set up WDPRDineReservations.BaseHybridViewController.viewWillAppear swizzle
+ (void)load {
    NSLog(@"[DisneyFreezeFix] Loaded");

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class targetClass
        = NSClassFromString(@"WDPRDineReservations.BaseHybridViewController");

        SEL originalSelector
        = @selector(viewWillAppear:);

        SEL swizzledSelector
        = @selector(swizzled_viewWillAppear:);

        Method swizzledMethod
        = class_getInstanceMethod(
            self,
            swizzledSelector);

        class_addMethod(
            targetClass,
            method_getName(swizzledMethod),
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod));

        Method originalMethod
        = class_getInstanceMethod(
            targetClass,
            originalSelector);

        Method addedMethod
        = class_getInstanceMethod(
            targetClass,
            swizzledSelector);

        method_exchangeImplementations(
            originalMethod,
            addedMethod);
    });
}

/// When `WDPRDineReservations.BaseHybridViewController.viewWillAppear`
/// is called, temporarily disable calls to `-[UIGestureRecognizer setEnabled:]`
/// (or at least, make them no-ops)
- (void)swizzled_viewWillAppear:(BOOL)animated {
    shouldSkipSetEnabled = YES;
    [self swizzled_viewWillAppear:animated];
    shouldSkipSetEnabled = NO;
}

@end

@implementation UIGestureRecognizer (DisneyFreezeFix)

/// Set up UIGestureRecognizer.setEnabled swizzle
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        SEL originalSelector
        = @selector(setEnabled:);
        SEL swizzledSelector
        = @selector(swizzled_setEnabled:);

        Method originalMethod
        = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod
        = class_getInstanceMethod(class, swizzledSelector);

        method_exchangeImplementations(
            originalMethod,
            swizzledMethod);
    });
}

#pragma mark - Method Swizzling

/// Replacement implementation of  `-[UIGestureRecognizer setEnabled:]`
/// that skips the original impl if `shouldSkipSetEnabled` is set
- (void)swizzled_setEnabled:(BOOL)setEnabled {
    if (shouldSkipSetEnabled) {
        NSLog(@"[DisneyFreezeFix] Skipping");
        return;
    }

    [self swizzled_setEnabled:setEnabled];
}

@end
