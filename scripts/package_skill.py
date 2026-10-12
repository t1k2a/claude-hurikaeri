"""Build the reviewed text-only Dev Rewind ZIP (Python standard library only)."""
import argparse
import hashlib
from pathlib import Path
import zipfile

FILES = {
    'skills/dev-rewind/SKILL.md': 'dev-rewind/SKILL.md',
    'skills/dev-rewind/README.md': 'dev-rewind/README.md',
    'skills/dev-rewind/default-template.md': 'dev-rewind/default-template.md',
    'skills/dev-rewind/references/optional-operations.md': 'dev-rewind/references/optional-operations.md',
    'skills/dev-rewind/examples/synthetic-session.md': 'dev-rewind/examples/synthetic-session.md',
    'LICENSE': 'dev-rewind/LICENSE',
}


def build(root, output):
    root, output = Path(root).resolve(), Path(output)
    entries = []
    for source, destination in FILES.items():
        path = root / source
        if path.is_symlink() or not path.resolve().is_relative_to(root):
            raise ValueError(f'Package source must be a regular in-tree file: {source}')
        data = path.read_bytes()
        data.decode('utf-8')
        entries.append((destination, data))
    with zipfile.ZipFile(output, 'x', compression=zipfile.ZIP_DEFLATED) as archive:
        for destination, data in entries:
            archive.writestr(destination, data)
    return output


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = build(Path(__file__).resolve().parents[1], args.output)
    print(result.resolve())
    print('sha256:', hashlib.sha256(result.read_bytes()).hexdigest())
