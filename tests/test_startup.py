import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "script.sh"


class StartupTest(unittest.TestCase):
    def test_startup_directory(self):
        for mode, expected in (("empty", 77), ("checkout", 77), ("unrelated", 1)):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                source = root / "source"
                source.mkdir()
                if mode == "checkout":
                    (source / ".repo").mkdir()
                elif mode == "unrelated":
                    (source / "keep.txt").write_text("keep")
                repo = root / "repo"
                repo.write_text('#!/bin/bash\n[ "$1" = init ] || exit 78\nexit 77\n')
                repo.chmod(0o755)
                result = subprocess.run(
                    ["bash", str(SCRIPT)], cwd=source, capture_output=True, text=True,
                    env={**os.environ, "PATH": f"{root}:{os.environ['PATH']}"},
                )
                self.assertEqual(result.returncode, expected, result.stderr)
                if mode == "unrelated":
                    self.assertEqual((source / "keep.txt").read_text(), "keep")


if __name__ == "__main__":
    unittest.main()
