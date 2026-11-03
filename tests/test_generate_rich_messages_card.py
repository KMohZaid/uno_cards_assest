import subprocess
import unittest
from pathlib import Path


REPO_DIR = Path(__file__).resolve().parents[1]
GENERATOR = REPO_DIR / "generate_rich_messages_card.py"
OUTPUT_IMAGE = REPO_DIR / "auto_output/rich/classic_colorblind/png/b_3.png"


class RichCardGeneratorTest(unittest.TestCase):
    def test_generated_card_has_vertical_white_padding_and_stays_two_to_one(self):
        subprocess.run(["python", str(GENERATOR)], check=True, capture_output=True, text=True)

        width, height = map(
            int,
            subprocess.run(
                ["magick", "identify", "-format", "%w %h", str(OUTPUT_IMAGE)],
                check=True,
                capture_output=True,
                text=True,
            ).stdout.split(),
        )
        _source_width, source_height = map(
            int,
            subprocess.run(
                [
                    "magick",
                    "identify",
                    "-format",
                    "%w %h",
                    str(REPO_DIR / "images/classic_colorblind/webp/b_3.webp"),
                ],
                check=True,
                capture_output=True,
                text=True,
            ).stdout.split(),
        )

        self.assertEqual(width, height * 2)
        self.assertGreater(height, source_height)
        self.assertLess(height - source_height, height)


if __name__ == "__main__":
    unittest.main()
