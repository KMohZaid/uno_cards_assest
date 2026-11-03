"""Build wide (2:1) UNO card PNGs for Rich inline messages.

The original card PNG is centered without resizing on a white canvas whose
width is twice its height. Outputs go to auto_output/rich/classic_colorblind/png.
Requires ImageMagick's ``magick`` command.
"""

from pathlib import Path
import subprocess

REPO_DIR = Path(__file__).resolve().parent
SOURCE_DIR = REPO_DIR / "images" / "classic_colorblind" / "webp"
OUTPUT_DIR = REPO_DIR / "auto_output" / "rich" / "classic_colorblind" / "png"


def main() -> None:
    if not SOURCE_DIR.is_dir():
        raise SystemExit(f"Source WebP directory does not exist: {SOURCE_DIR}")

    sources = sorted(SOURCE_DIR.glob("*.webp"))
    if not sources:
        raise SystemExit(f"No source WebP files found in: {SOURCE_DIR}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for source in sources:
        identify = subprocess.run(
            ["magick", "identify", "-format", "%w %h", str(source)],
            check=True,
            capture_output=True,
            text=True,
        )
        _width, source_height = map(int, identify.stdout.split())
        canvas_height = round(source_height * 1.1)
        canvas_width = canvas_height * 2
        output = OUTPUT_DIR / f"{source.stem}.png"
        subprocess.run(
            [
                "magick",
                str(source),
                "-background",
                "white",
                "-alpha",
                "remove",
                "-alpha",
                "off",
                "-gravity",
                "center",
                "-extent",
                f"{canvas_width}x{canvas_height}",
                str(output),
            ],
            check=True,
        )
        print(f"{source.name}: {canvas_width}x{canvas_height} -> {output}")


if __name__ == "__main__":
    main()
