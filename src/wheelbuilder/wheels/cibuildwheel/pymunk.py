from wheelbuilder.platforminfo import SDK
from wheelbuilder.platforms import Android_arm64, Android_x86_64
from wheelbuilder.protocols import CiWheelBase


class Pymunk(CiWheelBase):
    def env(self):
        env = self.base_env()
        if self.platform.sdk == SDK.android:
            env["CIBW_ENVIRONMENT_ANDROID"] = " ".join(
                [
                    'LDFLAGS="$LDFLAGS -llog -lm"',
                    'PIP_EXTRA_INDEX_URL="https://pypi.anaconda.org/pyswift/simple"',
                ]
            )
        return env

    @classmethod
    def supported_platforms(cls):
        return [Android_arm64(), Android_x86_64()]
