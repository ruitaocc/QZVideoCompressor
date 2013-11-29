# QZVideoCompressor
======
This project have three main components: 1,QZAssetPicker; 2,QZVideoPreviewer; 3,QZVideoCompressor.
1,In iOS7,the system's UIImagePicker can't filter assets flexible. By the QZAssetPicker, we can select asset from the local asset library with filter, the filter can set as allPhotos/allVideos/allAssets, and multiselect as well.
2,The usally way to compress vedio is use AVAssetExportSession, and set its quality level. The AVAssetExportSession can only compress vedio into three quality levels (AVAssetExportPresetLowQuality/AVAssetExportPresetMediumQuality/AVAssetExportPresetHighQuality). This is not suitable for network transfer, although we can set the shouldOptimizeForNetworkUse property, it doesn't work.
  By the QZVideoCompressor, we use AssetReader to read the original asset, and then AssetWriter to compress the vedio. With this, we can config the compress setting flexible.(AVVideoAverageBitRateKey/AVVideoWidthKey/AVVideoHeightKey/AVVideoMaxKeyFrameIntervalKey...).
3.The QZVideoPreviewer is used to preview the video asset select by QZAssetPicker. And it support range slider, used to clip time range of the vedio. It pass a parameter CMTime timeRange to the QZVideoCompressor; then the AssetReader just process the video in timeRange.


## Screens
![QZVideoCompressor screen](https://storage.googleapis.com/ruitaocc-upload/IMG_0285.png "QZVideoCompressor screen")
![QZVideoCompressor screen](https://storage.googleapis.com/ruitaocc-upload/IMG_0286.png "QZVideoCompressor screen")
![QZVideoCompressor screen](https://storage.googleapis.com/ruitaocc-upload/IMG_0287.png "QZVideoCompressor screen")
![QZVideoCompressor screen](https://storage.googleapis.com/ruitaocc-upload/IMG_0288.png "QZVideoCompressor screen")
![QZVideoCompressor screen](https://storage.googleapis.com/ruitaocc-upload/IMG_0289.png "QZVideoCompressor screen")
![QZVideoCompressor screen](https://storage.googleapis.com/ruitaocc-upload/IMG_0290.png "QZVideoCompressor screen")      
![QZVideoCompressor screen](https://storage.googleapis.com/ruitaocc-upload/IMG_0291.png "QZVideoCompressor screen")
![QZVideoCompressor screen](https://storage.googleapis.com/ruitaocc-upload/IMG_0292.png "QZVideoCompressor screen")
![QZVideoCompressor screen](https://storage.googleapis.com/ruitaocc-upload/IMG_0293.png "QZVideoCompressor screen")
 


## Requirements

- iOS 6+,
- ARC.

## Installation

1. Drop `QZVideoCompressor` files into your project.
2. Add `AssetsLibrary.framework`, `MediaPlayer.framework`, `AudioToolbox.framework`, `AVFoundation.framework`, to your project.
3. Add below code to use it in a class.
``` objective-c
#import "QZAssetsPickerController.h"
#import "QZLocalVideoCompressEngine.h"
#import "QZVideoPreviewController.h"`
```

## Example Usage

``` objective-c
    QZAssetsPickerController *picker = [[QZAssetsPickerController alloc] init];
    picker.maxinumSelection = 1;
    picker.assetsFilter = AS_ALLVIDEOS;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:NULL];
```

## Protocols

``` objective-c
-(void)assetsPickerController:(QZAssetsPickerController *)picker didFinishPickingAssetUrl:(NSURL *)assetUrl
```


## Customization

This project contains three main components, they work together to fullfill the "select-clip-compress" process, they can work independently for exactly purpose.

## Contact

vectorcai

- https://github.com/ruitaocc
- http://www.cairuitao.com

## License
QZVideoCompressor is available under the MIT license. See the LICENSE file for more info.
