from pathlib import Path

from wheelbuilder import tools
from wheelbuilder.protocols import CiWheelBase


class Blosc2(CiWheelBase):
    def env(self):
        env = self.base_env()
        env["CIBW_XBUILD_TOOLS_IOS"] = "cmake ninja git"
        env["CIBW_BEFORE_BUILD_IOS"] = " && ".join(
            [
                "pip install --only-binary=numpy 'scikit-build-core>=0.11.0' 'cython>=3' 'numpy>=2.1'",
                "python -c \"import sys,sysconfig,os;sp=sysconfig.get_path('purelib');ni=next((os.path.join(sp,d) for d in('numpy/_core/include','numpy/core/include')if os.path.isdir(os.path.join(sp,d))),sp+'/numpy/_core/include');open('/tmp/blosc2_cmake_init.cmake','w').write('set(Python_EXECUTABLE \\\"'+sys.executable+'\\\" CACHE FILEPATH \\\"\\\" FORCE)\\nset(Python_NumPy_INCLUDE_DIRS \\\"'+ni+'\\\" CACHE PATH \\\"\\\" FORCE)\\n')\"",
                "MINIEXPR_SRC=/tmp/blosc2_ios_miniexpr",
                "rm -rf $MINIEXPR_SRC",
                "git clone --depth 1 https://github.com/Blosc/miniexpr.git $MINIEXPR_SRC",
                "cd $MINIEXPR_SRC && git fetch --depth 1 origin f2faef741c4c507bf6a03167c72ce7f92c6f0ae8 && git checkout f2faef741c4c507bf6a03167c72ce7f92c6f0ae8",
                "sed -i '' 's/int rc = system(cmd);/int rc = -1; (void)cmd;/' $MINIEXPR_SRC/src/*.c",
                # merge_static_libs.cmake only uses libtool when SYSTEM_NAME=Darwin.
                # For iOS cross-compile CMAKE_SYSTEM_NAME=iOS, so it falls through to
                # ar -M (GNU ar MRI script) which macOS ar doesn't support.
                # Fix: clone c-blosc2, patch the cmake script to also handle iOS, then
                # tell FetchContent to use our patched local copy.
                "CBLOSC2_SRC=/tmp/blosc2_ios_cblosc2",
                "rm -rf $CBLOSC2_SRC",
                "git clone --depth 1 --branch v3.0.3 https://github.com/Blosc/c-blosc2.git $CBLOSC2_SRC",
                "sed -i '' 's/STREQUAL \"Darwin\")/STREQUAL \"Darwin\" OR SYSTEM_NAME STREQUAL \"iOS\")/' $CBLOSC2_SRC/cmake/merge_static_libs.cmake",
            ]
        )
        env["CIBW_ENVIRONMENT_IOS"] = " ".join(
            [
                'PIP_EXTRA_INDEX_URL="https://pypi-index.psychowaspx.workers.dev/simple/"',
                'SKBUILD_CMAKE_ARGS="-DFETCHCONTENT_SOURCE_DIR_MINIEXPR=/tmp/blosc2_ios_miniexpr;-DFETCHCONTENT_SOURCE_DIR_BLOSC2=/tmp/blosc2_ios_cblosc2;-C;/tmp/blosc2_cmake_init.cmake"',
            ]
        )
        env["CIBW_BUILD_FRONTEND"] = "pip; args: --no-build-isolation"
        return env

    def patches(self):
        return [
            "https://raw.githubusercontent.com/Py-Swift/LibraryPatches/refs/heads/master/blosc2-ios.patch",
        ]

    def apply_patches(self, target: Path, working_dir: Path) -> None:
        for url in self.patches():
            patch_file = tools.download_url(url, working_dir)
            tools.git_apply(patch_file, target)
