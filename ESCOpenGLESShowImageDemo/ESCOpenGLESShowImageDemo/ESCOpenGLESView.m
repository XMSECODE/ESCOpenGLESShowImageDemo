//
//  ESCOpenGLESView.m
//  ESCOpenGLESShowImageDemo
//
//  Created by xiang on 2018/7/25.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import "ESCOpenGLESView.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface ESCOpenGLESView ()

@property(nonatomic,strong)EAGLContext* context;

@property(nonatomic,assign)GLuint frameBuffer;

@property(nonatomic,assign)GLuint renderBuffer;

@property(nonatomic,assign)GLint backingWidth;

@property(nonatomic,assign)GLint backingHeight;

@property(nonatomic,assign)GLuint texture;

@property(nonatomic,assign)GLuint mGLProgId;

@property(nonatomic,assign)GLuint mGLTextureCoords;

@property(nonatomic,assign)GLuint mGLPosition;

@property(nonatomic,assign)GLuint mGLUniformTexture;

@property(nonatomic,strong)dispatch_queue_t openglesQueue;

@end

@implementation ESCOpenGLESView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupOPENGLES];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupOPENGLES];
}

- (void)setupOPENGLES {
    self.openglesQueue = dispatch_queue_create("openglesqueue", DISPATCH_QUEUE_SERIAL);
    //设置layer属性
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    NSDictionary *dict = @{kEAGLDrawablePropertyRetainedBacking:@(NO),
                           kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGB565
                           };
    [eaglLayer setOpaque:YES];
    [eaglLayer setDrawableProperties:dict];
    //创建上下文
    [self setupContext];
    //创建缓冲区buffer
    [self setupBuffers];
    
    //设置GPU程序
    [self setupGPUProgram];
}

- (void)setupContext {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (self.context == nil) {
        NSLog(@"create context failed!");
        return;
    }
    BOOL result = [EAGLContext setCurrentContext:self.context];
    if (result == NO) {
        NSLog(@"set context failed!");
    }
}

- (void)setupBuffers {
    //创建帧缓冲区
    glGenFramebuffers(1, &_frameBuffer);
    //绑定缓冲区
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    //创建绘制缓冲区
    glGenRenderbuffers(1, &_renderBuffer);
    //绑定缓冲区
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    //为绘制缓冲区分配内存
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    
    //获取绘制缓冲区像素高度/宽度
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    //将绘制缓冲区绑定到帧缓冲区
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    
    //检查状态
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete frame buffer object!");
        return;
    }
    GLenum glError = glGetError();
    if (GL_NO_ERROR != glError) {
        NSLog(@"failed to setup GL %x", glError);
    }
}

#pragma mark - 编译GPU程序
- (void)setupGPUProgram {
    GLuint vertexShader = [self compileShader:@"vertexshader.vtsd" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"fragmentshader.fmsd" withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE)
    {
        GLchar message[256];
        glGetProgramInfoLog(programHandle, sizeof(message), 0, &message[0]);
        NSString *messageStr = [NSString stringWithUTF8String:message];
        NSLog(@"%@", messageStr);
        return;
    }
    
    glUseProgram(programHandle);
    self.mGLProgId = programHandle;
    _mGLPosition = glGetAttribLocation(programHandle, "position");
    glEnableVertexAttribArray(_mGLPosition);
    
    _mGLTextureCoords = glGetAttribLocation(programHandle, "texcoord");
    glEnableVertexAttribArray(_mGLTextureCoords);
    
    _mGLUniformTexture = glGetUniformLocation(programHandle, "texSampler");
    
}

- (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType {
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:nil];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString)
    {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        return 0;
    }
    
    // create ID for shader
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // define shader text
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // compile shader
    glCompileShader(shaderHandle);
    
    // verify the compiling
    GLint compileSucess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSucess);
    if (compileSucess == GL_FALSE)
    {
        GLchar message[256];
        glGetShaderInfoLog(shaderHandle, sizeof(message), 0, &message[0]);
        NSString *messageStr = [NSString stringWithUTF8String:message];
        NSLog(@"----%@", messageStr);
        return 0;
    }
    
    return shaderHandle;
}

- (void)createTexWithImage:(UIImage *)image {
    //创建纹理
    glGenTextures(1, &_texture);
    //绑定纹理
    glBindTexture(GL_TEXTURE_2D, _texture);
    
    //设置过滤参数
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    //设置映射规则
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //获取图片RGBA数据
    void *pixels = NULL;
    [self getImageRGBAData:image data:&pixels];
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image.size.width, image.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    free(pixels);
}

#pragma mark - 通过opengles加载image

- (void)shaderImage:(UIImage *)image {
    BOOL result = [EAGLContext setCurrentContext:self.context];
    if (result == NO) {
        NSLog(@"set context failed!");
    }
    if (self.texture) {
        glDeleteTextures(1, &_texture);
    }
    
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self createTexWithImage:image];
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    //设置物体坐标
    GLfloat vertices[] = {
        -1.0,-1.0,
        1.0,-1.0,
        -1.0,1.0,
        1.0,1.0
    };
    glVertexAttribPointer(_mGLPosition, 2, GL_FLOAT, 0, 0, vertices);
    
    //设置纹理坐标
    GLfloat texCoords2[] = {
        0,1,
        1,1,
        0,0,
        1,0
    };
    glVertexAttribPointer(_mGLTextureCoords, 2, GL_FLOAT, 0, 0, texCoords2);
    
    //传递纹理对象
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glUniform1i(_mGLUniformTexture, 0);
    
    //执行绘制操作
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    
    //删除不使用纹理
    glDeleteTextures(1, &_texture);
    //解绑纹理
    glBindTexture(GL_TEXTURE_2D, 0);
    
}
- (void)loadImage:(UIImage *)image {
    dispatch_async(self.openglesQueue, ^{
        [self shaderImage:image];
    });
}

#pragma mark - 获取图片RGBA数据
- (void)getImageRGBAData:(UIImage *)image data:(void * *)data {
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(image.CGImage);
    CGColorSpaceRef colorRef = CGColorSpaceCreateDeviceRGB();
    
    float width = image.size.width;
    float height = image.size.height;
    
    // Get source image data
    uint8_t *imageData = (uint8_t *) malloc(width * height * 4);
    
    CGContextRef imageContext = CGBitmapContextCreate(imageData,
                                                      width, height,
                                                      8, width * 4,
                                                      colorRef, alphaInfo);
    
    CGContextDrawImage(imageContext, CGRectMake(0, 0, width, height), image.CGImage);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(colorRef);
    *data = imageData;
}

@end
