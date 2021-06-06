#import "MusicPlugin.h"
#if __has_include(<music/music-Swift.h>)
#import <music/music-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "music-Swift.h"
#endif

@implementation MusicPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMusicPlugin registerWithRegistrar:registrar];
}
@end
