"""Check skill entry points and every skill shell script (Python standard library)."""
import argparse
from pathlib import Path
import subprocess


def check(root, bash='bash', shellcheck=None):
    root = Path(root)
    directories = sorted(path for path in (root / 'skills').glob('*') if path.is_dir())
    if not directories:
        raise ValueError('No skill directories found')
    for directory in directories:
        if not (directory / 'SKILL.md').is_file():
            raise ValueError(f'Missing SKILL.md: {directory}')
    for script in sorted((root / 'skills').rglob('*.sh')):
        print(f'Checking {script}', flush=True)
        subprocess.run([bash, '-n', str(script)], check=True)
        if shellcheck:
            subprocess.run([shellcheck, '--severity=warning', str(script)], check=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bash', default='bash', help='Bash executable path')
    parser.add_argument('--shellcheck', help='Also run this ShellCheck executable')
    args = parser.parse_args()
    check(Path(__file__).resolve().parents[1], args.bash, args.shellcheck)
