import subprocess
from pathlib import Path

ACCOUNT_ID = "fc1487d061af4129ef6816901a48c870"
BUCKET = "pypi-packages"
ENDPOINT = f"https://{ACCOUNT_ID}.r2.cloudflarestorage.com"
WHEELS_DIR = Path(__file__).parent.parent / "wheels"


def aws(*args: str) -> list[str]:
    return ["aws", "s3", "--profile", "r2", "--endpoint-url", ENDPOINT, *args]


def upload(local: Path, s3_key: str, content_type: str = "application/octet-stream") -> None:
    subprocess.run(
        aws("cp", str(local), f"s3://{BUCKET}/{s3_key}", "--content-type", content_type),
        check=True,
    )


def main() -> None:
    wheels = sorted(WHEELS_DIR.glob("*.whl"))
    if not wheels:
        print("No wheels found in wheels/")
        return

    print(f"Uploading {len(wheels)} wheels...")
    for whl in wheels:
        print(f"  packages/{whl.name}")
        upload(whl, f"packages/{whl.name}")

    print("\nDone!")
    print("Index auto-updates at: https://pypi-index.psychowaspx.workers.dev/simple/")


if __name__ == "__main__":
    main()
