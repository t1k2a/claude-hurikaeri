import importlib.util
from pathlib import Path
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]


class PackageTests(unittest.TestCase):
    def builder(self):
        """Load the packaging module without running its command-line entry point."""
        script = ROOT / 'scripts/package_skill.py'
        self.assertTrue(script.is_file(), 'A fixed-allowlist package builder is required')
        spec = importlib.util.spec_from_file_location('package_skill', script)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_only_reviewed_files_and_license_are_packaged(self):
        """Exclude unrelated private files while preserving every allowlisted source byte."""
        builder = self.builder()
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            for source in builder.FILES:
                path = root / source
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes((ROOT / source).read_bytes())
            (root / 'skills/dev-rewind/private-report.json').write_text('PRIVATE SENTINEL')
            (root / 'skills/dev-rewind/.env').write_text('SECRET SENTINEL')
            (root / 'skills/dev-rewind/local-helper.exe').write_bytes(b'BINARY SENTINEL')
            output = root / 'result.zip'
            builder.build(root, output)
            with zipfile.ZipFile(output) as archive:
                self.assertEqual(set(archive.namelist()), set(builder.FILES.values()))
                self.assertEqual(archive.read('dev-rewind/LICENSE'), (ROOT / 'LICENSE').read_bytes())
                self.assertEqual(archive.read('dev-rewind/SKILL.md').decode('utf-8').splitlines()[:2], ['---', 'name: dev-rewind'])
                self.assertNotIn(b'SENTINEL', b''.join(archive.read(n) for n in archive.namelist()))

    def test_missing_file_does_not_create_partial_archive(self):
        """Fail before creating an archive when required source files are absent."""
        builder = self.builder()
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            output = root / 'result.zip'
            with self.assertRaises(FileNotFoundError):
                builder.build(root, output)
            self.assertFalse(output.exists())

    def test_existing_output_is_not_overwritten(self):
        """Preserve an existing destination even when all package sources are valid."""
        builder = self.builder()
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder) / 'result.zip'
            output.write_bytes(b'existing')
            with self.assertRaises(FileExistsError):
                builder.build(ROOT, output)
            self.assertEqual(output.read_bytes(), b'existing')


if __name__ == '__main__':
    unittest.main()
