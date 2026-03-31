#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include <hx/CFFI.h>

extern "C" void hx_onFilePicked(const char* path);

@interface FilePickerDelegate : NSObject <UIDocumentPickerDelegate>
@end

@implementation FilePickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (url) {
        hx_onFilePicked([[url path] UTF8String]);
    }
}

@end

static FilePickerDelegate *delegate;

extern "C" void openFilePicker() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
        UIViewController *root = window.rootViewController;

        UIDocumentPickerViewController *picker =
        [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[
            UTTypeAudio,
            UTTypeJSON
        ]];

        delegate = [FilePickerDelegate new];
        picker.delegate = delegate;

        [root presentViewController:picker animated:YES completion:nil];
    });
}

// Haxe callback
extern "C" void hx_onFilePicked(const char* path) {
    value func = val_field(val_id("FilePickerCallback"), val_id("onFilePicked"));
    if (val_is_function(func)) {
        val_call1(func, alloc_string(path));
    }
}
