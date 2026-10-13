"""Execute README snippets in isolated directories, never in the real skills home."""
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InstallCommandTests(unittest.TestCase):
    def snippet(self, language):
        """Extract the exact install example readers will copy from the README."""
        readme = (ROOT / 'skills/dev-rewind/README.md').read_text(encoding='utf-8')
        blocks = re.findall(r'```' + language + r'\n(.*?)\n```', readme, re.S)
        self.assertEqual(len(blocks), 1, f'Expected one {language} install example')
        return blocks[0]

    def exercise(self, language, executable):
        """Test both host destinations for success and safe refusal cases."""
        snippet = self.snippet(language)
        for agent, host in [('claude', '.claude'), ('codex', '.agents')]:
            for scenario in ['first-install', 'existing-destination', 'missing-source']:
                with self.subTest(language=language, agent=agent, scenario=scenario):
                    with tempfile.TemporaryDirectory(prefix='dev rewind install ') as folder:
                        root = Path(folder)
                        repo = root / 'repo space'
                        repo.mkdir()
                        test_home = root / 'home space'
                        target = test_home / host / 'skills/dev-rewind'
                        source = repo / 'skills/dev-rewind'
                        if scenario != 'missing-source':
                            source.mkdir(parents=True)
                            (source / 'SKILL.md').write_text('synthetic skill', encoding='utf-8')
                            (source / '.hidden-example').write_text('hidden', encoding='utf-8')
                            (source / 'references').mkdir()
                            (source / 'references/example.md').write_text('reference', encoding='utf-8')
                        if scenario == 'existing-destination':
                            target.mkdir(parents=True)
                            (target / 'SKILL.md').write_text('keep existing', encoding='utf-8')
                        if language == 'sh':
                            code = 'test_home=$1\n' + snippet.replace('$HOME', '$test_home')
                            code = code.replace('agent=claude', f'agent={agent}')
                            home_argument = test_home.as_posix()
                            # Git Bash accepts a forward-slash Windows drive path.
                            script = root / 'install.sh'
                            script.write_bytes(code.encode('utf-8'))
                            command = [executable, str(script), home_argument]
                        else:
                            code = '$testHome = $args[0]\n' + snippet.replace('$HOME', '$testHome')
                            code = code.replace("$agent = 'claude'", f"$agent = '{agent}'")
                            script = root / 'install.ps1'
                            script.write_text(code, encoding='utf-8-sig')
                            command = [executable, '-NoProfile', '-NonInteractive',
                                       '-ExecutionPolicy', 'Bypass', '-File', str(script), str(test_home)]
                        self.assertNotIn('$HOME', code)
                        result = subprocess.run(command, cwd=repo, capture_output=True,
                                                text=True, errors='replace', timeout=30)
                        if scenario == 'first-install':
                            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                            self.assertEqual((target / 'SKILL.md').read_text(), 'synthetic skill')
                            self.assertTrue((target / '.hidden-example').is_file())
                            self.assertTrue((target / 'references/example.md').is_file())
                            self.assertFalse((target / 'dev-rewind').exists())
                        else:
                            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                            if scenario == 'existing-destination':
                                self.assertEqual((target / 'SKILL.md').read_text(), 'keep existing')
                                self.assertEqual(list(target.iterdir()), [target / 'SKILL.md'])
                            else:
                                self.assertFalse(test_home.exists())

    def test_posix_install_example(self):
        """Exercise the portable shell example using Git Bash or system sh."""
        git_bash = Path('C:/Program Files/Git/bin/bash.exe')
        executable = str(git_bash) if git_bash.is_file() else shutil.which('sh')
        if not executable:
            self.skipTest('No POSIX shell available')
        self.exercise('sh', executable)

    def test_powershell_install_example(self):
        """Exercise the PowerShell example without changing the real HOME variable."""
        executable = shutil.which('powershell') or shutil.which('pwsh')
        if not executable:
            self.skipTest('No PowerShell available')
        self.exercise('powershell', executable)


if __name__ == '__main__':
    unittest.main()
