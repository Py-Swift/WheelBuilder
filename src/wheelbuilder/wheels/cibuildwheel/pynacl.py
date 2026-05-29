from wheelbuilder.platforminfo import SDK
from wheelbuilder.protocols import CiWheelBase


class Pynacl(CiWheelBase):
    def env(self):
        env = self.base_env()
        if self.platform.sdk == SDK.android:
            env["CIBW_ENVIRONMENT_ANDROID"] = 'SODIUM_INSTALL="bundled" PKG_CONFIG_PATH=""'
        else:
            # cffi is a build dependency of pynacl. On iOS, cffi tries to compile
            # from source and fails (ffi.h not found). We have pre-built cffi iOS
            # wheels on R2; configure pip globally before any wheel builds so that
            # cibuildwheel's build-dep installer also sees the extra index.
            env["CIBW_BEFORE_ALL_IOS"] = (
                "pip config set global.extra-index-url "
                "https://pypi-index.psychowaspx.workers.dev/simple/"
            )
        return env
