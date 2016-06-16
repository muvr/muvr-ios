@import UIKit;

int main(int argc, char * argv[]) {
    @autoreleasepool {
        @try {
            return UIApplicationMain(argc, argv, nil, @"Muvr.MRAppDelegate");
        } @catch (NSException *ex) {
            NSLog(@"%@", ex);
            NSLog(@"%@", ex.description);
        }
    }
}
