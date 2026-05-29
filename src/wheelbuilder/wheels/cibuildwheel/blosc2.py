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
                "python -c \"import sys,numpy; open('/tmp/blosc2_cmake_init.cmake','w').write('set(Python_EXECUTABLE \\\"'+sys.executable+'\\\" CACHE FILEPATH \\\"\\\" FORCE)\\nset(Python_NumPy_INCLUDE_DIRS \\\"'+numpy.get_include()+'\\\" CACHE PATH \\\"\\\" FORCE)\\n')\"",
                "MINIEXPR_SRC=/tmp/blosc2_ios_miniexpr",
                "rm -rf $MINIEXPR_SRC",
                "git clone --depth 1 https://github.com/Blosc/miniexpr.git $MINIEXPR_SRC",
                "cd $MINIEXPR_SRC && git fetch --depth 1 origin f2faef741c4c507bf6a03167c72ce7f92c6f0ae8 && git checkout f2faef741c4c507bf6a03167c72ce7f92c6f0ae8",
                "sed -i '' 's/int rc = system(cmd);/int rc = -1; (void)cmd;/' $MINIEXPR_SRC/src/miniexpr.c",
            ]
        )
        env["CIBW_ENVIRONMENT_IOS"] = " ".join(
            [
                'PIP_EXTRA_INDEX_URL="https://pypi-index.psychowaspx.workers.dev/simple/"',
                'SKBUILD_CMAKE_ARGS="-DFETCHCONTENT_SOURCE_DIR_MINIEXPR=/tmp/blosc2_ios_miniexpr -C /tmp/blosc2_cmake_init.cmake"',
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
