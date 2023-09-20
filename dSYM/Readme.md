# dSYM

DWARF 的全称是 debugging with attributed record formats，是一种源码调试信息的格式，注意，DWARF 是一种格式。

dSYM 的全称是 Debug Symbols，也就是调试符号，一般称为符号文件，注意，dSYM 是一个文件，里面的内容是 DWARF 格式的信息。


### dSYM生成的时机
![image.png](https://upload-images.jianshu.io/upload_images/1846524-5e3d1946f937f7c4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### xcode 编译的过程
![image.png](https://upload-images.jianshu.io/upload_images/1846524-debc5e94e52827eb.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
### dSYM 生成过程

#### 1、测试源码

```
// main.m
void run(void) {
    
}
void eat(void) {
    
}

int global = 10;

int main(int argc, const char * argv[]) {
    global = 11;
    global = 12;
    run();
    eat();
    return 0;
}
```

#### 2、生成带调试信息的目标文件
            
* -c Run all of the above, plus the assembler, generating a target ".o" object file.
* -g Generate debug information.

```
clang -c -g main.m -o main.o
```

#### 3.查看文件内是否有调试信息

* --private-header: Display only the first format specific file header.

* -m, --macho: Use Mach-O specific object file parser. Commands and other options may behave differently when used with --macho.

```
objdump --macho --private-headers main.o 
```

__DWARF段保存的是调试信息

![image.png](https://upload-images.jianshu.io/upload_images/1846524-1086b7cd0de704ee.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
#### 4.生成dSYM文件

```
clang -g1 main.m -o main
```
#### 5.查看dSYM文件内容

```
dwarfdump main.dSYM
```

![image.png](https://upload-images.jianshu.io/upload_images/1846524-e3593dcfc701d101.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


### dSYM 解析
1、这里生成了一个简单的iOS工程，在touchbegan方法加了一个数组越界的操作。项目是直接利用模拟器直接运行的，点击屏幕会崩溃，这里要注意打开debug模式下的dsym生成配置。

```
@interface ViewController ()

@property(nonatomic, strong) NSArray *array;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.array = @[@1];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.array[1];
}

@end

```

![image.png](https://upload-images.jianshu.io/upload_images/1846524-028114c2a3817ef7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


![image.png](https://upload-images.jianshu.io/upload_images/1846524-ff05fd93ca076796.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
生成的dsym在 ~/Library/Developer/Xcode/DerivedData/AppName-xxxxx/Build/Products/Debug-iphonesimulator/路径下

2、运行xocde，点击屏幕产生崩溃

![image.png](https://upload-images.jianshu.io/upload_images/1846524-8add9501b1cc8fa1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

3、查看符号表信息,得出macho的起始地址
```
objdump --macho --private-headers SYMTest.app/SYMTest
```

![image.png](https://upload-images.jianshu.io/upload_images/1846524-159337dbffbab207.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

4、在xcode 断点模式下输入image list得到mahco的实际入口地址

![image.png](https://upload-images.jianshu.io/upload_images/1846524-0969058c48b6b120.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

镜像入口地址-macho起始地址=偏移地址
```
  0x00000001043fa000
- 0x0000000100000000
= 0x00000000043fa000
```

拿到崩溃地址0x00000001043fbe77，让其减去上面的偏移地址就得到了其在dSYM中的地址

```
 0x00000001043fbe77
-0x00000000043fa000
=0x0000000100001E77
```

利用
```
dwarfdump --lookup 0x0000000100001E77 SYMTest.app.dSYM
```

就得到了该地址对应的方法名

![image.png](https://upload-images.jianshu.io/upload_images/1846524-128237f3c6d759ce.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
和xcode显示的是一样的。