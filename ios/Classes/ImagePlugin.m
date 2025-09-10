#import "ImagePlugin.h"
#if __has_include(<image_plugin/image_plugin-Swift.h>)
#import <image_plugin/image_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "image_plugin-Swift.h"
#endif

@implementation ImagePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftImagePlugin registerWithRegistrar:registrar];
}
@end
