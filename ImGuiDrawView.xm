#import "Esp/ImGuiDrawView.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>
#include "IMGUI/imgui.h"
#include "IMGUI/imgui_impl_metal.h"
#import "Esp/CaptainHook.h"
#import "copsmm.h"
#import "theme.h"
#include "KittyMemory/KittyInclude.hpp"
#include <thread>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <mach/mach.h>
#include "RetroGaming.h"

#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale [UIScreen mainScreen].scale


@interface ImGuiDrawView () <MTKViewDelegate>
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@end


@implementation ImGuiDrawView


struct MemPatches
{

    MemoryPatch DCI;
    MemoryPatch RADAR;
    MemoryPatch SPREAD;
    MemoryPatch HITBOX;
    MemoryPatch HEADHITBOX;
    MemoryPatch RECOIL;
    MemoryPatch RECOIL1;

} gPatches;


MemoryFileInfo g_BaseInfo;


static bool MenDeal = true;
int tab = 0;

bool Radar = false;
bool CI = false;
bool Spread = false;
bool Rain = false;
bool Recoil = false;
int Rain1 = false;
const char *Rain_items[2] = {"Body", "Head"};


uintptr_t radar;
uintptr_t dci;
uintptr_t spread;
uintptr_t hitbox;
uintptr_t headhitbox;
uintptr_t recoil;
uintptr_t recoil1;
uintptr_t unityBase;


void PatternScan(){
timer(10){

g_BaseInfo = KittyMemory::getMemoryFileInfo("UnityFramework");

unityBase = g_BaseInfo.address;

const mach_header_64 *some_binary_header = (const mach_header_64 *)g_BaseInfo.header;

unsigned long text_seg_size = 0;
uintptr_t text_scan_start = (uintptr_t)getsegmentdata(some_binary_header, "__TEXT", &text_seg_size);
    uintptr_t text_scan_end = text_scan_start + text_seg_size;



radar = KittyScanner::findIdaPatternFirst(text_scan_start, text_scan_end, "C8 09 80 52 C9 00 80 52 28 41 88 1A");

dci = KittyScanner::findIdaPatternFirst(text_scan_start, text_scan_end, "E8 4F 40 B9 1F 05 00 31 ? ? ? ? E0 0B 40 F9");

spread = KittyScanner::findIdaPatternFirst(text_scan_start, text_scan_end, "01 0C 40 F9 00 D9 40 BD 62 66 40 BD 61 3A 40 BD 63 46 41 39 62 42 41 39");

hitbox = KittyScanner::findIdaPatternFirst(text_scan_start, text_scan_end, "2D 28 20 1E D7 7A 40 F9 ? ? ? ? E8 1A 40 B9 18 05 00 71");

headhitbox = KittyScanner::findIdaPatternFirst(text_scan_start, text_scan_end, "00 18 21 1E 01 10 2E 1E 02 58 21 1E 08 20 20 1E E0 03 27 1E 42 5C 20 1E");

recoil = KittyScanner::findIdaPatternFirst(text_scan_start, text_scan_end, "01 09 2A 1E 81 22 00 BD 20 09 20 1E 80 1E 00 BD");

recoil1 = KittyScanner::findIdaPatternFirst(text_scan_start, text_scan_end, "21 08 28 1E 0A 4E A8 52 42 01 27 1E 40 18 20 1E");



gPatches.RADAR = MemoryPatch::createWithAsm(radar, MP_ASM_ARM64, "mov w8, #0x6");

gPatches.DCI = MemoryPatch::createWithAsm(dci + 0x4, MP_ASM_ARM64, "mov x0, #0x1");

gPatches.SPREAD = MemoryPatch::createWithAsm(spread - 0x24, MP_ASM_ARM64, "ret");

gPatches.HITBOX = MemoryPatch::createWithAsm(hitbox + 0x10, MP_ASM_ARM64, "subs w24, w8, #5");

gPatches.HEADHITBOX = MemoryPatch::createWithAsm(headhitbox + 0x10, MP_ASM_ARM64, "fmov s0, #31");

gPatches.RECOIL = MemoryPatch::createWithAsm(recoil + 0x8, MP_ASM_ARM64, "fadd s0, s0, s0");

gPatches.RECOIL1 = MemoryPatch::createWithAsm(recoil1 + 0x4, MP_ASM_ARM64, "mov w10, #0");



});

}

__attribute__((constructor)) void init()
{
    std::thread(PatternScan).detach();
}




- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];

    if (!self.device) abort();

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;

    ImGui::StyleColorsDark();
    embraceTheDarkness();
    

io.Fonts->AddFontFromMemoryCompressedTTF(RetroGaming, compressedRetroGamingSize, 20);
    
    ImGui_ImplMetal_Init(_device);

    return self;
}

+ (void)showChange:(BOOL)open
{
    MenDeal = open;
}

- (MTKView *)mtkView
{
    return (MTKView *)self.view;
}

- (void)loadView
{

 

    CGFloat w = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width;
    CGFloat h = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height;
    self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    self.mtkView.clipsToBounds = YES;


 

}



#pragma mark - Interaction

- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches)
    {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled)
        {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView*)view
{
   
    
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 60);
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

        if (MenDeal == true) {
            [self.view setUserInteractionEnabled:YES];
        } else if (MenDeal == false) {
            [self.view setUserInteractionEnabled:NO];
        }

        MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
        if (renderPassDescriptor != nil)
        {
            id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            [renderEncoder pushDebugGroup:@"ImGui Jane"];

            ImGui_ImplMetal_NewFrame(renderPassDescriptor);
            ImGui::NewFrame();
            
            ImFont* font = ImGui::GetFont();
            font->Scale = 15.f / font->FontSize;
            
            CGFloat x = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width) - 420) / 2;
            CGFloat y = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height) - 280) / 2;
            
            ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);
            ImGui::SetNextWindowSize(ImVec2(420, 280), ImGuiCond_FirstUseEver);
            
            if (MenDeal == true)
            {                
                ImGui::Begin("Critical Ops Cheats (All Version)", &MenDeal, ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoScrollbar);

uintptr_t test40 = radar - unityBase;
uintptr_t test50 = dci + 0x4 - unityBase;
uintptr_t test60 = spread - 0x24 - unityBase;
uintptr_t test70 = hitbox + 0x10 - unityBase;
uintptr_t test80 = headhitbox + 0x10 - unityBase;
uintptr_t test90 = recoil + 0x8 - unityBase;
uintptr_t test100 = recoil1 + 0x4 - unityBase;


NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

std::string Bundle([bundleIdentifier UTF8String]);

NSString *safari_localizedShortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

std::string Version([safari_localizedShortVersion UTF8String]);

NSString *safari_displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];

std::string sName([safari_displayName UTF8String]);



ImGui::Columns(2);
ImGui::SetColumnOffset(1, 120);

ImGui::Spacing();
if(ImGui::Button("Main", ImVec2(100.0f, 40.0f))){
tab = 0;
}
ImGui::Spacing();
if(ImGui::Button("Info", ImVec2(100.0f, 40.0f))){
tab = 1;
}



ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Spacing();
ImGui::Text("     Made By");
ImGui::Text("  EvilBunny420");


ImGui::NextColumn();
switch(tab){
case 0:
ImGui::BeginChild("##scroll1");
ImGui::Spacing();
ImGui::Spacing();
ImGui::Checkbox("Radar", &Radar);
ImGui::Checkbox("CharacterIndicator", &CI);
ImGui::Checkbox("No Spread", &Spread);
ImGui::Checkbox("No Recoil", &Recoil);
ImGui::Checkbox("Rain", &Rain);
if(Rain){
ImGui::Combo("##rain", &Rain1, Rain_items, 2);
}
ImGui::EndChild();
break;
case 1:
if (ImGui::CollapsingHeader("App Info"))
{
ImGui::Text("App Name: \n%s", sName.c_str());
ImGui::Text("App Bundle: \n%s", Bundle.c_str());
ImGui::Text("App Version: \n%s", Version.c_str());
}
if (ImGui::CollapsingHeader("Offsets & Bytes"))
{
ImGui::BeginChild("##scroll2");
ImGui::Text("Radar: %p", (void *)test40);
ImGui::Text("Radar Bytes: 0x%s", gPatches.RADAR.get_CurrBytes().c_str());
ImGui::Spacing();
ImGui::Text("CharacterIndicator: %p", (void *)test50);
ImGui::Text("CharacterIndicator Bytes: 0x%s", gPatches.DCI.get_CurrBytes().c_str());
ImGui::Spacing();
ImGui::Text("No Spread: %p", (void *)test60);
ImGui::Text("No Spread Bytes: 0x%s", gPatches.SPREAD.get_CurrBytes().c_str());
ImGui::Spacing();
ImGui::Text("No Recoil: %p", (void *)test90);
ImGui::Text("No Recoil Bytes: 0x%s", gPatches.RECOIL.get_CurrBytes().c_str());
ImGui::Spacing();
ImGui::Text("No Recoil1: %p", (void *)test100);
ImGui::Text("No Recoil1 Bytes: 0x%s", gPatches.RECOIL1.get_CurrBytes().c_str());
ImGui::Spacing();
ImGui::Text("Rain BODY: %p", (void *)test70);
ImGui::Text("Rain BODY Bytes: 0x%s", gPatches.HITBOX.get_CurrBytes().c_str());
ImGui::Spacing();
ImGui::Text("Rain HEAD: %p", (void *)test80);
ImGui::Text("Rain HEAD Bytes: 0x%s", gPatches.HEADHITBOX.get_CurrBytes().c_str());
ImGui::EndChild();
}
break;
}



if(Radar){
gPatches.RADAR.Modify();
} else {
gPatches.RADAR.Restore();
}


if(CI){
gPatches.DCI.Modify();
} else {
gPatches.DCI.Restore();
}


if(Spread){
gPatches.SPREAD.Modify();
} else {
gPatches.SPREAD.Restore();
}

if(Recoil){
gPatches.RECOIL.Modify();
gPatches.RECOIL1.Modify();
} else {
gPatches.RECOIL.Restore();
gPatches.RECOIL1.Restore();
}

if (Rain) {
switch (Rain1) {
case 0:
gPatches.HITBOX.Modify();
gPatches.HEADHITBOX.Modify();
break;
case 1:
gPatches.HITBOX.Restore();
gPatches.HEADHITBOX.Modify();
break;
}
} else {
gPatches.HITBOX.Restore();
gPatches.HEADHITBOX.Restore();
}





                ImGui::End();
                
            }
            ImDrawList* draw_list = ImGui::GetBackgroundDrawList();

            ImGui::Render();
            ImDrawData* draw_data = ImGui::GetDrawData();
            ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);
          
            [renderEncoder popDebugGroup];
            [renderEncoder endEncoding];

            [commandBuffer presentDrawable:view.currentDrawable];
        }

        [commandBuffer commit];
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size
{
    
}

@end
