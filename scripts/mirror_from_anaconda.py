"""
Download all wheels from anaconda.org/PySwift and upload them to Cloudflare R2.
The simple index is served dynamically by the Cloudflare Worker — no index files needed.

Usage:
    python scripts/mirror_from_anaconda.py
"""

import json
import subprocess
import tempfile
import urllib.request
from pathlib import Path


ANACONDA_USER = "PySwift"
ANACONDA_API = "https://api.anaconda.org"

ACCOUNT_ID = "fc1487d061af4129ef6816901a48c870"
BUCKET = "pypi-packages"
ENDPOINT = f"https://{ACCOUNT_ID}.r2.cloudflarestorage.com"

SKIP_PYTHON_TAGS = {"cp311"}

# All known packages on the pyswift channel
KNOWN_PACKAGES = [
    "aiohttp",
    "apsw",
    "bcrypt",
    "bitarray",
    "Brotli",
    "cffi",
    "contourpy",
    "coverage",
    "cryptography",
    "ffmpeg",
    "greenlet",
    "kiwisolver",
    "libffmpeg",
    "libpng",
    "materialyoucolor",
    "matplotlib",
    "msgpack",
    "netifaces",
    "numpy",
    "opencv-python",
    "orjson",
    "pandas",
    "pendulum",
    "pillow",
    "pycryptodome",
    "pydantic_core",
    "pymunk",
    "regex",
    "SQLAlchemy",
]


def aws(*args: str) -> list[str]:
    return ["aws", "s3", "--profile", "r2", "--endpoint-url", ENDPOINT, *args]


def fetch_json(url: str) -> object:
    req = urllib.request.Request(url, headers={"User-Agent": "WheelBuilder/1.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def is_wanted(basename: str) -> bool:
    parts = basename.removesuffix(".whl").split("-")
    # parts: name-version-pythontag-abitag-platform
    if len(parts) >= 3 and parts[2] in SKIP_PYTHON_TAGS:
        return False
    return True


def get_package_wheels(package_name: str) -> list[dict]:
    """Return list of {basename, url} for all wanted .whl files in a package."""
    try:
        data = fetch_json(f"{ANACONDA_API}/package/{ANACONDA_USER}/{package_name}")
    except Exception as e:
        print(f"  [skip] {package_name}: {e}")
        return []

    wheels = []
    for f in data.get("files", []):
        basename = f.get("basename", "")
        if not basename.endswith(".whl"):
            continue
        if not is_wanted(basename):
            continue
        url = f["download_url"]
        if url.startswith("//"):
            url = "https:" + url
        wheels.append({"basename": basename, "url": url})
    return wheels


def download_wheel(url: str, dest: Path) -> bool:
    req = urllib.request.Request(url, headers={"User-Agent": "WheelBuilder/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            dest.write_bytes(r.read())
        return True
    except Exception as e:
        print(f"  [error] download failed: {e}")
        return False


def upload(local: Path, s3_key: str) -> None:
    subprocess.run(
        aws("cp", str(local), f"s3://{BUCKET}/{s3_key}"),
        check=True,
        capture_output=True,
    )


def list_existing_wheels() -> set[str]:
    """List wheel files already in the bucket."""
    result = subprocess.run(
        aws("ls", f"s3://{BUCKET}/packages/", "--recursive"),
        capture_output=True,
        text=True,
    )
    names = set()
    for line in result.stdout.splitlines():
        parts = line.split()
        if parts:
            key = parts[-1]
            if key.endswith(".whl"):
                names.add(Path(key).name)
    return names


def main() -> None:
    print("Checking existing wheels in bucket...")
    existing = list_existing_wheels()
    print(f"  {len(existing)} wheels already in bucket")

    all_wheels: dict[str, str] = {}  # basename -> download_url

    print(f"\nFetching package metadata from anaconda.org ({len(KNOWN_PACKAGES)} packages)...")
    for pkg in KNOWN_PACKAGES:
        wheels = get_package_wheels(pkg)
        if wheels:
            print(f"  {pkg}: {len(wheels)} wheels")
            for w in wheels:
                all_wheels[w["basename"]] = w["url"]
        else:
            print(f"  {pkg}: (none found)")

    to_download = {name: url for name, url in all_wheels.items() if name not in existing}
    print(f"\n{len(all_wheels)} total wheels found, {len(to_download)} new to upload")

    if not to_download:
        print("Nothing new to download.")
        return

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        for i, (basename, url) in enumerate(sorted(to_download.items()), 1):
            dest = tmp / basename
            print(f"  [{i}/{len(to_download)}] {basename}")
            if download_wheel(url, dest):
                upload(dest, f"packages/{basename}")
                dest.unlink(missing_ok=True)

    print(f"\nDone! {len(to_download)} wheels uploaded.")
    print("Index auto-updates at: https://pypi-index.psychowaspx.workers.dev/simple/")


if __name__ == "__main__":
    main()
