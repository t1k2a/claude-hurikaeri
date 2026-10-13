"""Ensure CI rejects broken scripts and missing skill entry points."""
import importlib.util
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SkillCheckTests(unittest.TestCase):
    def checker(self):
        spec = importlib.util.spec_from_file_location('check_skills', ROOT / 'scripts/check_skills.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_invalid_script_fails_even_with_valid_sibling(self):
        git_bash = Path('C:/Program Files/Git/bin/bash.exe')
        bash = str(git_bash) if git_bash.is_file() else shutil.which('bash')
        if not bash:
            self.skipTest('Bash unavailable')
        checker = self.checker()
        with tempfile.TemporaryDirectory(prefix='skill check ') as folder:
            root = Path(folder)
            skill = root / 'skills/demo space'
            skill.mkdir(parents=True)
            (skill / 'SKILL.md').write_text('synthetic skill', encoding='utf-8')
            (skill / 'a broken.sh').write_bytes(b'if then\n')
            (skill / 'z valid.sh').write_bytes(b'echo safe\n')
            with self.assertRaises(subprocess.CalledProcessError):
                checker.check(root, bash)
            (skill / 'a broken.sh').write_bytes(b'echo fixed\n')
            checker.check(root, bash)

    def test_missing_skill_entry_is_rejected(self):
        checker = self.checker()
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'skills/incomplete').mkdir(parents=True)
            with self.assertRaisesRegex(ValueError, 'SKILL.md'):
                checker.check(root, 'unused-bash')

    def test_empty_skills_directory_is_rejected(self):
        checker = self.checker()
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaisesRegex(ValueError, 'No skill directories'):
                checker.check(Path(folder), 'unused-bash')


if __name__ == '__main__':
    unittest.main()
