//
//  NXInitHPSCpp2OC.m
//  skyDRM
//
//  Created by helpdesk on 3/20/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

#import "NXInitHPSCpp2OC.h"
#import "hps.h"
#import "visualize_license.h"


@implementation NXInitHPSCpp2OC : NSObject
static HPS::World *world;

+(void) initWorld{
    world = new HPS::World(VISUALIZE_LICENSE);
}

+(void) deInitWorld{
    delete world;
}

+(void)setMaterialLibraryDir{
    NSString * curDir = [[NSFileManager defaultManager] currentDirectoryPath];
    NSString * bundleDir = [[NSBundle mainBundle] bundlePath];
    
    NSString * material_dir = [bundleDir stringByAppendingPathComponent:@"/Contents/materials"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:material_dir isDirectory:nil] == NO) {
        
        material_dir = [curDir stringByAppendingPathComponent:@"/Contents/materials"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:material_dir isDirectory:nil] == NO) {
            // please set your working directory
            printf("set your ");
        }
    }
    world->SetMaterialLibraryDirectory([material_dir UTF8String]);
}

@end
