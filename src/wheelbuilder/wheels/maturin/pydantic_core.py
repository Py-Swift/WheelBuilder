from wheelbuilder.platforminfo import SDK
from wheelbuilder.protocols import MaturinWheelBase


class Pydantic_core(MaturinWheelBase):
    def env(self):
        e = super().env()
        if self.platform.sdk != SDK.android:
            # pyo3-ffi's build script requires _sysconfigdata*.py in
            # PYO3_CROSS_LIB_DIR. Python-iOS-support xcframework omits this
            # file. Create a minimal stub so the build can proceed.
            stub = (
                "python3 -c "
                "'import pathlib,sysconfig;"
                'd=sysconfig.get_config_var("LIBDIR");'
                "p=pathlib.Path(d);"
                'list(p.glob("_sysconfigdata*.py")) or '
                '(p/"_sysconfigdata__arm-apple-ios.py").write_text("build_time_vars={}")'
                "'"
            )
            existing = e.get("CIBW_BEFORE_BUILD", "pip install maturin")
            e["CIBW_BEFORE_BUILD_IOS"] = f"{stub} && {existing}"
        return e
