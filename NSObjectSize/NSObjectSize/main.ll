; ModuleID = 'main.m'
source_filename = "main.m"
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.15.0"

%0 = type opaque
%struct._objc_cache = type opaque
%struct._class_t = type { %struct._class_t*, %struct._class_t*, %struct._objc_cache*, i8* (i8*, i8*)**, %struct._class_ro_t* }
%struct._class_ro_t = type { i32, i32, i32, i8*, i8*, %struct.__method_list_t*, %struct._objc_protocol_list*, %struct._ivar_list_t*, i8*, %struct._prop_list_t* }
%struct.__method_list_t = type { i32, i32, [0 x %struct._objc_method] }
%struct._objc_method = type { i8*, i8*, i8* }
%struct._objc_protocol_list = type { i64, [0 x %struct._protocol_t*] }
%struct._protocol_t = type { i8*, i8*, %struct._objc_protocol_list*, %struct.__method_list_t*, %struct.__method_list_t*, %struct.__method_list_t*, %struct.__method_list_t*, %struct._prop_list_t*, i32, i32, i8**, i8*, %struct._prop_list_t* }
%struct._ivar_list_t = type { i32, i32, [0 x %struct._ivar_t] }
%struct._ivar_t = type { i64*, i8*, i8*, i32, i32 }
%struct._prop_list_t = type { i32, i32, [0 x %struct._prop_t] }
%struct._prop_t = type { i8*, i8* }
%struct.__NSConstantString_tag = type { i32*, i32, i8*, i64 }

@_objc_empty_cache = external global %struct._objc_cache
@"OBJC_METACLASS_$_NSObject" = external global %struct._class_t
@OBJC_CLASS_NAME_ = private unnamed_addr constant [9 x i8] c"OCObject\00", section "__TEXT,__objc_classname,cstring_literals", align 1
@"_OBJC_METACLASS_RO_$_OCObject" = internal global %struct._class_ro_t { i32 129, i32 40, i32 40, i8* null, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @OBJC_CLASS_NAME_, i32 0, i32 0), %struct.__method_list_t* null, %struct._objc_protocol_list* null, %struct._ivar_list_t* null, i8* null, %struct._prop_list_t* null }, section "__DATA, __objc_const", align 8
@"OBJC_METACLASS_$_OCObject" = global %struct._class_t { %struct._class_t* @"OBJC_METACLASS_$_NSObject", %struct._class_t* @"OBJC_METACLASS_$_NSObject", %struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** null, %struct._class_ro_t* @"_OBJC_METACLASS_RO_$_OCObject" }, section "__DATA, __objc_data", align 8
@"OBJC_CLASS_$_NSObject" = external global %struct._class_t
@"_OBJC_CLASS_RO_$_OCObject" = internal global %struct._class_ro_t { i32 128, i32 8, i32 8, i8* null, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @OBJC_CLASS_NAME_, i32 0, i32 0), %struct.__method_list_t* null, %struct._objc_protocol_list* null, %struct._ivar_list_t* null, i8* null, %struct._prop_list_t* null }, section "__DATA, __objc_const", align 8
@"OBJC_CLASS_$_OCObject" = global %struct._class_t { %struct._class_t* @"OBJC_METACLASS_$_OCObject", %struct._class_t* @"OBJC_CLASS_$_NSObject", %struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** null, %struct._class_ro_t* @"_OBJC_CLASS_RO_$_OCObject" }, section "__DATA, __objc_data", align 8
@"OBJC_CLASSLIST_REFERENCES_$_" = internal global %struct._class_t* @"OBJC_CLASS_$_NSObject", section "__DATA,__objc_classrefs,regular,no_dead_strip", align 8
@__CFConstantStringClassReference = external global [0 x i32]
@.str = private unnamed_addr constant [4 x i8] c"%zd\00", section "__TEXT,__cstring,cstring_literals", align 1
@_unnamed_cfstring_ = private global %struct.__NSConstantString_tag { i32* getelementptr inbounds ([0 x i32], [0 x i32]* @__CFConstantStringClassReference, i32 0, i32 0), i32 1992, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i64 3 }, section "__DATA,__cfstring", align 8 #0
@"OBJC_LABEL_CLASS_$" = internal global [1 x i8*] [i8* bitcast (%struct._class_t* @"OBJC_CLASS_$_OCObject" to i8*)], section "__DATA,__objc_classlist,regular,no_dead_strip", align 8
@llvm.compiler.used = appending global [3 x i8*] [i8* getelementptr inbounds ([9 x i8], [9 x i8]* @OBJC_CLASS_NAME_, i32 0, i32 0), i8* bitcast (%struct._class_t** @"OBJC_CLASSLIST_REFERENCES_$_" to i8*), i8* bitcast ([1 x i8*]* @"OBJC_LABEL_CLASS_$" to i8*)], section "llvm.metadata"

; Function Attrs: noinline optnone ssp uwtable
define i32 @main(i32, i8**) #1 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i8**, align 8
  %6 = alloca %0*, align 8
  store i32 0, i32* %3, align 4
  store i32 %0, i32* %4, align 4
  store i8** %1, i8*** %5, align 8
  %7 = call i8* @llvm.objc.autoreleasePoolPush() #2
  %8 = load %struct._class_t*, %struct._class_t** @"OBJC_CLASSLIST_REFERENCES_$_", align 8
  %9 = bitcast %struct._class_t* %8 to i8*
  %10 = call i8* @objc_alloc_init(i8* %9)
  %11 = bitcast i8* %10 to %0*
  store %0* %11, %0** %6, align 8
  %12 = load %0*, %0** %6, align 8
  %13 = bitcast %0* %12 to i8*
  %14 = call i8* @objc_opt_class(i8* %13)
  %15 = call i64 @class_getInstanceSize(i8* %14)
  notail call void (i8*, ...) @NSLog(i8* bitcast (%struct.__NSConstantString_tag* @_unnamed_cfstring_ to i8*), i64 %15)
  %16 = load %0*, %0** %6, align 8
  %17 = bitcast %0* %16 to i8*
  %18 = call i64 @malloc_size(i8* %17)
  notail call void (i8*, ...) @NSLog(i8* bitcast (%struct.__NSConstantString_tag* @_unnamed_cfstring_ to i8*), i64 %18)
  %19 = bitcast %0** %6 to i8**
  call void @llvm.objc.storeStrong(i8** %19, i8* null) #2
  call void @llvm.objc.autoreleasePoolPop(i8* %7)
  ret i32 0
}

; Function Attrs: nounwind
declare i8* @llvm.objc.autoreleasePoolPush() #2

declare i8* @objc_alloc_init(i8*)

declare void @NSLog(i8*, ...) #3

declare i64 @class_getInstanceSize(i8*) #3

declare i8* @objc_opt_class(i8*)

declare i64 @malloc_size(i8*) #3

; Function Attrs: nounwind
declare void @llvm.objc.storeStrong(i8**, i8*) #2

; Function Attrs: nounwind
declare void @llvm.objc.autoreleasePoolPop(i8*) #2

attributes #0 = { "objc_arc_inert" }
attributes #1 = { noinline optnone ssp uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "darwin-stkchk-strong-link" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "probe-stack"="___chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind }
attributes #3 = { "correctly-rounded-divide-sqrt-fp-math"="false" "darwin-stkchk-strong-link" "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "probe-stack"="___chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6, !7}
!llvm.ident = !{!8}

!0 = !{i32 2, !"SDK Version", [3 x i32] [i32 10, i32 15, i32 4]}
!1 = !{i32 1, !"Objective-C Version", i32 2}
!2 = !{i32 1, !"Objective-C Image Info Version", i32 0}
!3 = !{i32 1, !"Objective-C Image Info Section", !"__DATA,__objc_imageinfo,regular,no_dead_strip"}
!4 = !{i32 4, !"Objective-C Garbage Collection", i32 0}
!5 = !{i32 1, !"Objective-C Class Properties", i32 64}
!6 = !{i32 1, !"wchar_size", i32 4}
!7 = !{i32 7, !"PIC Level", i32 2}
!8 = !{!"Apple clang version 11.0.3 (clang-1103.0.32.62)"}
