public let libffi_patch = """
diff -ur orig-libffi-3.4.7/generate-darwin-source-and-headers.py libffi-3.4.7/generate-darwin-source-and-headers.py
--- orig-libffi-3.4.7/generate-darwin-source-and-headers.py	2024-06-01 19:42:02
+++ libffi-3.4.7/generate-darwin-source-and-headers.py	2025-10-09 13:38:17
@@ -248,10 +248,10 @@
     copy_files('include', 'darwin_common/include', pattern='*.h')
 
     if generate_ios:
-        copy_src_platform_files(ios_simulator_i386_platform)
+        #copy_src_platform_files(ios_simulator_i386_platform)
         copy_src_platform_files(ios_simulator_x86_64_platform)
         copy_src_platform_files(ios_simulator_arm64_platform)
-        copy_src_platform_files(ios_device_armv7_platform)
+        #copy_src_platform_files(ios_device_armv7_platform)
         copy_src_platform_files(ios_device_arm64_platform)
     if generate_osx:
         copy_src_platform_files(desktop_x86_64_platform)
@@ -270,10 +270,10 @@
     platform_headers = collections.defaultdict(set)
 
     if generate_ios:
-        build_target(ios_simulator_i386_platform, platform_headers)
+        #build_target(ios_simulator_i386_platform, platform_headers)
         build_target(ios_simulator_x86_64_platform, platform_headers)
         build_target(ios_simulator_arm64_platform, platform_headers)
-        build_target(ios_device_armv7_platform, platform_headers)
+        #build_target(ios_device_armv7_platform, platform_headers)
         build_target(ios_device_arm64_platform, platform_headers)
     if generate_osx:
         build_target(desktop_x86_64_platform, platform_headers)
diff -ur orig-libffi-3.4.7/libffi.xcodeproj/project.pbxproj libffi-3.4.7/libffi.xcodeproj/project.pbxproj
--- orig-libffi-3.4.7/libffi.xcodeproj/project.pbxproj	2024-06-01 19:42:02
+++ libffi-3.4.7/libffi.xcodeproj/project.pbxproj	2025-10-09 13:21:20
@@ -24,8 +24,6 @@
 		DBFA715B187F1D8600A76262 /* types.c in Sources */ = {isa = PBXBuildFile; fileRef = DBFA7149187F1D8600A76262 /* types.c */; };
 		DBFA7177187F1D9B00A76262 /* ffi_arm64.c in Sources */ = {isa = PBXBuildFile; fileRef = DBFA716C187F1D9B00A76262 /* ffi_arm64.c */; };
 		DBFA7178187F1D9B00A76262 /* sysv_arm64.S in Sources */ = {isa = PBXBuildFile; fileRef = DBFA716D187F1D9B00A76262 /* sysv_arm64.S */; };
-		DBFA7179187F1D9B00A76262 /* ffi_armv7.c in Sources */ = {isa = PBXBuildFile; fileRef = DBFA716F187F1D9B00A76262 /* ffi_armv7.c */; };
-		DBFA717A187F1D9B00A76262 /* sysv_armv7.S in Sources */ = {isa = PBXBuildFile; fileRef = DBFA7170187F1D9B00A76262 /* sysv_armv7.S */; };
 		DBFA717E187F1D9B00A76262 /* ffi64_x86_64.c in Sources */ = {isa = PBXBuildFile; fileRef = DBFA7175187F1D9B00A76262 /* ffi64_x86_64.c */; };
 		DBFA718F187F1DA100A76262 /* ffi_x86_64.h in Headers */ = {isa = PBXBuildFile; fileRef = DBFA7183187F1DA100A76262 /* ffi_x86_64.h */; };
 		DBFA7191187F1DA100A76262 /* fficonfig_x86_64.h in Headers */ = {isa = PBXBuildFile; fileRef = DBFA7185187F1DA100A76262 /* fficonfig_x86_64.h */; };
@@ -34,9 +32,7 @@
 		DBFA7196187F1DA100A76262 /* ffi64_x86_64.c in Sources */ = {isa = PBXBuildFile; fileRef = DBFA718C187F1DA100A76262 /* ffi64_x86_64.c */; };
 		FDB52FB31F6144FA00AA92E6 /* unix64_x86_64.S in Sources */ = {isa = PBXBuildFile; fileRef = 43E9A5C61D352C1500926A8F /* unix64_x86_64.S */; };
 		FDB52FB51F6144FA00AA92E6 /* ffi64_x86_64.c in Sources */ = {isa = PBXBuildFile; fileRef = DBFA7175187F1D9B00A76262 /* ffi64_x86_64.c */; };
-		FDB52FB61F6144FA00AA92E6 /* ffi_armv7.c in Sources */ = {isa = PBXBuildFile; fileRef = DBFA716F187F1D9B00A76262 /* ffi_armv7.c */; };
 		FDB52FB71F6144FA00AA92E6 /* closures.c in Sources */ = {isa = PBXBuildFile; fileRef = DBFA7143187F1D8600A76262 /* closures.c */; };
-		FDB52FB81F6144FA00AA92E6 /* sysv_armv7.S in Sources */ = {isa = PBXBuildFile; fileRef = DBFA7170187F1D9B00A76262 /* sysv_armv7.S */; };
 		FDB52FB91F6144FA00AA92E6 /* ffiw64_x86_64.c in Sources */ = {isa = PBXBuildFile; fileRef = 43B5D3F71D35473200D1E1FD /* ffiw64_x86_64.c */; };
 		FDB52FBA1F6144FA00AA92E6 /* prep_cif.c in Sources */ = {isa = PBXBuildFile; fileRef = DBFA7147187F1D8600A76262 /* prep_cif.c */; };
 		FDB52FBC1F6144FA00AA92E6 /* raw_api.c in Sources */ = {isa = PBXBuildFile; fileRef = DBFA7148187F1D8600A76262 /* raw_api.c */; };
@@ -46,14 +42,12 @@
 		FDB52FC01F6144FA00AA92E6 /* win64_x86_64.S in Sources */ = {isa = PBXBuildFile; fileRef = 43B5D3F91D3547CE00D1E1FD /* win64_x86_64.S */; };
 		FDB52FD01F614A8B00AA92E6 /* ffi.h in CopyFiles */ = {isa = PBXBuildFile; fileRef = DBFA713E187F1D8600A76262 /* ffi.h */; };
 		FDB52FD11F614AA700AA92E6 /* ffi_arm64.h in CopyFiles */ = {isa = PBXBuildFile; fileRef = DBFA715E187F1D9B00A76262 /* ffi_arm64.h */; };
-		FDB52FD21F614AAB00AA92E6 /* ffi_armv7.h in CopyFiles */ = {isa = PBXBuildFile; fileRef = DBFA715F187F1D9B00A76262 /* ffi_armv7.h */; };
 		FDB52FD41F614AB500AA92E6 /* ffi_x86_64.h in CopyFiles */ = {isa = PBXBuildFile; fileRef = DBFA7161187F1D9B00A76262 /* ffi_x86_64.h */; };
 		FDB52FD51F614AE200AA92E6 /* ffi.h in CopyFiles */ = {isa = PBXBuildFile; fileRef = DBFA713E187F1D8600A76262 /* ffi.h */; };
 		FDB52FD61F614AEA00AA92E6 /* ffi_arm64.h in CopyFiles */ = {isa = PBXBuildFile; fileRef = DBFA715E187F1D9B00A76262 /* ffi_arm64.h */; };
 		FDB52FD71F614AED00AA92E6 /* ffi_x86_64.h in CopyFiles */ = {isa = PBXBuildFile; fileRef = DBFA7161187F1D9B00A76262 /* ffi_x86_64.h */; };
 		FDB52FD81F614B8700AA92E6 /* ffitarget.h in CopyFiles */ = {isa = PBXBuildFile; fileRef = DBFA7141187F1D8600A76262 /* ffitarget.h */; };
 		FDB52FD91F614B8E00AA92E6 /* ffitarget_arm64.h in CopyFiles */ = {isa = PBXBuildFile; fileRef = DBFA7166187F1D9B00A76262 /* ffitarget_arm64.h */; };
-		FDB52FDA1F614B9300AA92E6 /* ffitarget_armv7.h in CopyFiles */ = {isa = PBXBuildFile; fileRef = DBFA7167187F1D9B00A76262 /* ffitarget_armv7.h */; };
 		FDB52FDD1F614BA900AA92E6 /* ffitarget_x86_64.h in CopyFiles */ = {isa = PBXBuildFile; fileRef = DBFA7169187F1D9B00A76262 /* ffitarget_x86_64.h */; };
 		FDB52FDE1F6155E300AA92E6 /* ffitarget.h in CopyFiles */ = {isa = PBXBuildFile; fileRef = DBFA7141187F1D8600A76262 /* ffitarget.h */; };
 		FDB52FDF1F6155EA00AA92E6 /* ffitarget_arm64.h in CopyFiles */ = {isa = PBXBuildFile; fileRef = DBFA7166187F1D9B00A76262 /* ffitarget_arm64.h */; };
@@ -83,11 +77,9 @@
 			files = (
 				FDB52FD01F614A8B00AA92E6 /* ffi.h in CopyFiles */,
 				FDB52FD11F614AA700AA92E6 /* ffi_arm64.h in CopyFiles */,
-				FDB52FD21F614AAB00AA92E6 /* ffi_armv7.h in CopyFiles */,
 				FDB52FD41F614AB500AA92E6 /* ffi_x86_64.h in CopyFiles */,
 				FDB52FD81F614B8700AA92E6 /* ffitarget.h in CopyFiles */,
 				FDB52FD91F614B8E00AA92E6 /* ffitarget_arm64.h in CopyFiles */,
-				FDB52FDA1F614B9300AA92E6 /* ffitarget_armv7.h in CopyFiles */,
 				FDB52FDD1F614BA900AA92E6 /* ffitarget_x86_64.h in CopyFiles */,
 			);
 			runOnlyForDeploymentPostprocessing = 0;
@@ -142,18 +134,13 @@
 		DBFA7148187F1D8600A76262 /* raw_api.c */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.c; path = raw_api.c; sourceTree = "<group>"; };
 		DBFA7149187F1D8600A76262 /* types.c */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.c; path = types.c; sourceTree = "<group>"; };
 		DBFA715E187F1D9B00A76262 /* ffi_arm64.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = ffi_arm64.h; sourceTree = "<group>"; };
-		DBFA715F187F1D9B00A76262 /* ffi_armv7.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = ffi_armv7.h; sourceTree = "<group>"; };
 		DBFA7161187F1D9B00A76262 /* ffi_x86_64.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = ffi_x86_64.h; sourceTree = "<group>"; };
 		DBFA7162187F1D9B00A76262 /* fficonfig_arm64.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = fficonfig_arm64.h; sourceTree = "<group>"; };
-		DBFA7163187F1D9B00A76262 /* fficonfig_armv7.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = fficonfig_armv7.h; sourceTree = "<group>"; };
 		DBFA7165187F1D9B00A76262 /* fficonfig_x86_64.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = fficonfig_x86_64.h; sourceTree = "<group>"; };
 		DBFA7166187F1D9B00A76262 /* ffitarget_arm64.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = ffitarget_arm64.h; sourceTree = "<group>"; };
-		DBFA7167187F1D9B00A76262 /* ffitarget_armv7.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = ffitarget_armv7.h; sourceTree = "<group>"; };
 		DBFA7169187F1D9B00A76262 /* ffitarget_x86_64.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = ffitarget_x86_64.h; sourceTree = "<group>"; };
 		DBFA716C187F1D9B00A76262 /* ffi_arm64.c */ = {isa = PBXFileReference; fileEncoding = 4; indentWidth = 2; lastKnownFileType = sourcecode.c.c; path = ffi_arm64.c; sourceTree = "<group>"; };
 		DBFA716D187F1D9B00A76262 /* sysv_arm64.S */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.asm; path = sysv_arm64.S; sourceTree = "<group>"; };
-		DBFA716F187F1D9B00A76262 /* ffi_armv7.c */ = {isa = PBXFileReference; fileEncoding = 4; indentWidth = 2; lastKnownFileType = sourcecode.c.c; path = ffi_armv7.c; sourceTree = "<group>"; };
-		DBFA7170187F1D9B00A76262 /* sysv_armv7.S */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.asm; path = sysv_armv7.S; sourceTree = "<group>"; };
 		DBFA7175187F1D9B00A76262 /* ffi64_x86_64.c */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.c; path = ffi64_x86_64.c; sourceTree = "<group>"; };
 		DBFA7183187F1DA100A76262 /* ffi_x86_64.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = ffi_x86_64.h; sourceTree = "<group>"; };
 		DBFA7185187F1DA100A76262 /* fficonfig_x86_64.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = fficonfig_x86_64.h; sourceTree = "<group>"; };
@@ -236,13 +223,10 @@
 			isa = PBXGroup;
 			children = (
 				DBFA715E187F1D9B00A76262 /* ffi_arm64.h */,
-				DBFA715F187F1D9B00A76262 /* ffi_armv7.h */,
 				DBFA7161187F1D9B00A76262 /* ffi_x86_64.h */,
 				DBFA7162187F1D9B00A76262 /* fficonfig_arm64.h */,
-				DBFA7163187F1D9B00A76262 /* fficonfig_armv7.h */,
 				DBFA7165187F1D9B00A76262 /* fficonfig_x86_64.h */,
 				DBFA7166187F1D9B00A76262 /* ffitarget_arm64.h */,
-				DBFA7167187F1D9B00A76262 /* ffitarget_armv7.h */,
 				DBFA7169187F1D9B00A76262 /* ffitarget_x86_64.h */,
 			);
 			path = include;
@@ -272,8 +256,6 @@
 			isa = PBXGroup;
 			children = (
 				43E9A5DB1D35374400926A8F /* internal.h */,
-				DBFA716F187F1D9B00A76262 /* ffi_armv7.c */,
-				DBFA7170187F1D9B00A76262 /* sysv_armv7.S */,
 			);
 			path = arm;
 			sourceTree = "<group>";
@@ -512,9 +494,7 @@
 			files = (
 				43E9A5C81D352C1500926A8F /* unix64_x86_64.S in Sources */,
 				DBFA717E187F1D9B00A76262 /* ffi64_x86_64.c in Sources */,
-				DBFA7179187F1D9B00A76262 /* ffi_armv7.c in Sources */,
 				DBFA714E187F1D8600A76262 /* closures.c in Sources */,
-				DBFA717A187F1D9B00A76262 /* sysv_armv7.S in Sources */,
 				43B5D3F81D35473200D1E1FD /* ffiw64_x86_64.c in Sources */,
 				DBFA7156187F1D8600A76262 /* prep_cif.c in Sources */,
 				DBFA7158187F1D8600A76262 /* raw_api.c in Sources */,
@@ -546,9 +526,7 @@
 			files = (
 				FDB52FB31F6144FA00AA92E6 /* unix64_x86_64.S in Sources */,
 				FDB52FB51F6144FA00AA92E6 /* ffi64_x86_64.c in Sources */,
-				FDB52FB61F6144FA00AA92E6 /* ffi_armv7.c in Sources */,
 				FDB52FB71F6144FA00AA92E6 /* closures.c in Sources */,
-				FDB52FB81F6144FA00AA92E6 /* sysv_armv7.S in Sources */,
 				FDB52FB91F6144FA00AA92E6 /* ffiw64_x86_64.c in Sources */,
 				FDB52FBA1F6144FA00AA92E6 /* prep_cif.c in Sources */,
 				FDB52FBC1F6144FA00AA92E6 /* raw_api.c in Sources */,
@@ -666,7 +644,7 @@
 				PRODUCT_NAME = ffi;
 				SDKROOT = iphoneos;
 				SKIP_INSTALL = YES;
-				VALID_ARCHS = "arm64 armv7 armv7s x86_64";
+				VALID_ARCHS = "arm64 x86_64";
 			};
 			name = Debug;
 		};
@@ -700,7 +678,7 @@
 				SDKROOT = iphoneos;
 				SKIP_INSTALL = YES;
 				VALIDATE_PRODUCT = YES;
-				VALID_ARCHS = "arm64 armv7 armv7s x86_64";
+				VALID_ARCHS = "arm64 x86_64";
 			};
 			name = Release;
 		};
"""
