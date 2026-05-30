from wheelbuilder.platforminfo import SDK
from wheelbuilder.protocols import CiWheelBase


class Pynacl(CiWheelBase):
    def env(self):
        env = self.base_env()
        if self.platform.sdk == SDK.android:
            env["CIBW_ENVIRONMENT_ANDROID"] = 'SODIUM_INSTALL="bundled" PKG_CONFIG_PATH=""'
        else:
            # cffi 2.0.0 removed _cffi_backend, which pynacl's setup.py requires
            # during the get_requires_for_build_wheel phase. Use --no-build-isolation
            # so we control the build env, and pre-install cffi<2 (1.x) which still
            # has _cffi_backend. libsodium is bundled to avoid a missing system dep.
            env["CIBW_BUILD_FRONTEND_IOS"] = "pip; args: --no-build-isolation"
            env["CIBW_BEFORE_BUILD_IOS"] = (
                "pip install 'cffi>=1.4.1,<2' setuptools wheel"
            )
            env["CIBW_ENVIRONMENT_IOS"] = 'SODIUM_INSTALL="bundled"'
        return env
