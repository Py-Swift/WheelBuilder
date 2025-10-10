let numpy_patch = """
diff -ur orig-numpy-2.3.3/numpy/_core/src/common/npy_cblas.h numpy-2.3.3/numpy/_core/src/common/npy_cblas.h
--- orig-numpy-2.3.3/numpy/_core/src/common/npy_cblas.h	2025-09-07 03:26:27
+++ numpy-2.3.3/numpy/_core/src/common/npy_cblas.h	2025-10-09 20:47:52
@@ -26,9 +26,14 @@
 #define CBLAS_INDEX size_t  /* this may vary between platforms */
 
 #ifdef ACCELERATE_NEW_LAPACK
-    #if __MAC_OS_X_VERSION_MAX_ALLOWED < 130300
+    #include "TargetConditionals.h"
+    #if TARGET_OS_OSX && __MAC_OS_X_VERSION_MAX_ALLOWED < 130300
         #ifdef HAVE_BLAS_ILP64
             #error "Accelerate ILP64 support is only available with macOS 13.3 SDK or later"
+        #endif
+    #elif TARGET_OS_IOS && __IPHONE_OS_VERSION_MAX_ALLOWED < 160400
+        #ifdef HAVE_BLAS_ILP64
+            #error "Accelerate ILP64 support is only available with iOS 16.4 SDK or later"
         #endif
     #else
         #define NO_APPEND_FORTRAN
diff -ur orig-numpy-2.3.3/numpy/meson.build numpy-2.3.3/numpy/meson.build
--- orig-numpy-2.3.3/numpy/meson.build	2025-09-07 03:26:27
+++ numpy-2.3.3/numpy/meson.build	2025-10-09 20:50:09
@@ -71,7 +71,7 @@
 blas_order = get_option('blas-order')
 if blas_order == ['auto']
   blas_order = []
-  if host_machine.system() == 'darwin'
+  if host_machine.system() == ['darwin', 'ios']
     blas_order += 'accelerate'
   endif
   if host_machine.cpu_family() == 'x86_64'
@@ -82,7 +82,7 @@
 lapack_order = get_option('lapack-order')
 if lapack_order == ['auto']
   lapack_order = []
-  if host_machine.system() == 'darwin'
+  if host_machine.system() == ['darwin', 'ios']
     lapack_order += 'accelerate'
   endif
   if host_machine.cpu_family() == 'x86_64'
diff -ur orig-numpy-2.3.3/pyproject.toml numpy-2.3.3/pyproject.toml
--- orig-numpy-2.3.3/pyproject.toml	2025-09-07 03:26:27
+++ numpy-2.3.3/pyproject.toml	2025-10-09 20:54:08
@@ -1,7 +1,8 @@
 [build-system]
 build-backend = "mesonpy"
 requires = [
-    "meson-python>=0.15.0",
+    #"meson-python>=0.15.0",
+    "meson-python @ git+https://github.com/freakboy3742/meson-python@ios-support",
     "Cython>=3.0.6",  # keep in sync with version check in meson.build
 ]
 
@@ -150,6 +151,23 @@
 before-test = "pip install -r {project}/requirements/test_requirements.txt"
 test-command = "bash {project}/tools/wheels/cibw_test_command.sh {project}"
 enable = ["cpython-freethreading", "pypy", "cpython-prerelease"]
+
+[tool.cibuildwheel.ios]
+# The build will use Accelerate on iOS 16.4 or above; but fall back to non-BLAS
+# for older iOS versions (because blas isn't available for iOS).
+config-settings = "setup-args=-Duse-ilp64=true setup-args=-Dallow-noblas=true build-dir=build"
+before-test = []
+test-requires = [
+    "hypothesis",
+    "pytest==7.4.0",
+    "pytest-cov==4.1.0",
+    "pytz",
+]
+test-sources = [
+    "numpy/tests",
+]
+test-command = "pytest --pyargs numpy -m 'not slow' -vv"
+xbuild-tools = ["ninja"]
 
 [tool.cibuildwheel.linux]
 manylinux-x86_64-image = "manylinux_2_28"
"""