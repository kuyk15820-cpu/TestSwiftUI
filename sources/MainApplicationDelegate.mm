#import "MainApplicationDelegate.h"
#import "SplashAnimation.h"
#import "app-Swift.h" 

@implementation MainApplicationDelegate {
    UIViewController *_rootViewController; // เปลี่ยนประเภทเป็น UIViewController ทั่วไป
    UIViewController *_mainContainer; 
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    self.window.windowLevel = UIWindowLevelNormal;
    
    if (@available(iOS 13.0, *)) {
        self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    
    _mainContainer = [[UIViewController alloc] init];
    _mainContainer.view.backgroundColor = [UIColor blackColor];
    [self.window setRootViewController:_mainContainer];
    
    UIViewController *launchVC = [[UIViewController alloc] init];
    launchVC.view.backgroundColor = [UIColor blackColor];
    [_mainContainer addChildViewController:launchVC];
    [_mainContainer.view addSubview:launchVC.view];
    [launchVC didMoveToParentViewController:_mainContainer];
    
    [self.window makeKeyAndVisible];

    [SplashAnimation sharedInstance].targetWindow = self.window;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[SplashAnimation sharedInstance] showWithRepeatCount:1 completion:^{
            
            //  จุดสำคัญ: เรียกหน้า MainView (SwiftUI) มาครอบด้วย UIHostingController 
            // โค้ดฝั่ง Swift ต้องประกาศ @objc คลาสแปลงไว้ (ดูวิธีทำด้านล่าง)
            self->_rootViewController = [SwiftViewFactory createMainView]; 
            
            // ในโค้ด Swift ของ MainView เราใส่ NavigationStack ไว้แล้ว 
            // ดังนั้นเราไม่จำเป็นต้องเอา UINavigationController มาครอบซ้ำอีกครับ 
            // สามารถสั่งเปลี่ยนหน้าผ่าน CrossDissolve เข้าสู่หน้าหลักได้โดยตรงเลย
            
            [UIView transitionWithView:self->_mainContainer.view
                              duration:0.5
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                
                for (UIViewController *child in self->_mainContainer.childViewControllers) {
                    [child willMoveToParentViewController:nil];
                    [child.view removeFromSuperview];
                    [child removeFromParentViewController];
                }
                
                [self->_mainContainer addChildViewController:self->_rootViewController];
                self->_rootViewController.view.frame = self->_mainContainer.view.bounds;
                [self->_mainContainer.view addSubview:self->_rootViewController.view];
                [self->_rootViewController didMoveToParentViewController:self->_mainContainer];
                
            } completion:nil];
            
        }];
    });

    return YES;
}

@end
