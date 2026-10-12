"""Run documented read-only Git commands against synthetic data, never user repos."""
from pathlib import Path
import subprocess
import tempfile
import unittest


class GitWorkflowTests(unittest.TestCase):
    def git(self, repo, *args, check=True):
        """Run Git with explicit arguments against a synthetic repository."""
        return subprocess.run(['git', '-C', str(repo), *args], check=check,
                              capture_output=True, text=True, encoding='utf-8')

    def test_spaces_staged_unstaged_untracked_and_secret_body(self):
        """Collect change metadata without reading untracked secret-file contents."""
        with tempfile.TemporaryDirectory(prefix='dev rewind ') as folder:
            repo = Path(folder)
            self.git(repo, 'init')
            (repo / 'tracked.txt').write_text('original\n')
            self.git(repo, 'add', 'tracked.txt')
            self.git(repo, '-c', 'user.name=Synthetic Test', '-c',
                     'user.email=synthetic@example.invalid', 'commit', '-m', 'Add demo file')
            (repo / 'tracked.txt').write_text('staged\n')
            self.git(repo, 'add', 'tracked.txt')
            (repo / 'tracked.txt').write_text('unstaged\n')
            (repo / '.env').write_text('SYNTHETIC_SECRET_BODY=not-real\n')
            outputs = []
            for args in [
                ['rev-parse', '--show-toplevel'], ['branch', '--show-current'],
                ['log', '--since=24 hours ago', '--no-merges', '--max-count=50', '--format=%h %s'],
                ['diff', '--no-ext-diff', '--stat'],
                ['diff', '--no-ext-diff', '--cached', '--stat'],
                ['ls-files', '--others', '--exclude-standard'],
            ]:
                outputs.append(self.git(repo, *args).stdout)
            self.assertIn('Add demo file', outputs[2])
            self.assertIn('tracked.txt', outputs[3])
            self.assertIn('tracked.txt', outputs[4])
            self.assertIn('.env', outputs[5])
            self.assertNotIn('SYNTHETIC_SECRET_BODY', ''.join(outputs))
            self.assertEqual((repo / 'tracked.txt').read_text(), 'unstaged\n')

    def test_empty_and_non_git_repository_failures_are_distinct(self):
        """Distinguish an empty Git repository from a directory with no repository."""
        with tempfile.TemporaryDirectory() as folder:
            repo = Path(folder)
            self.assertNotEqual(self.git(repo, 'rev-parse', '--show-toplevel', check=False).returncode, 0)
            self.git(repo, 'init')
            self.assertEqual(self.git(repo, 'rev-parse', '--show-toplevel').returncode, 0)
            self.assertNotEqual(self.git(repo, 'log', '--oneline', check=False).returncode, 0)


if __name__ == '__main__':
    unittest.main()
