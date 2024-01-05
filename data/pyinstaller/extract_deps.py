import tomllib
import sys
from pathlib import Path

def load_dependencies(path="pyproject.toml"):
    with open(path, "rb") as f:
        data = tomllib.load(f)

    deps = data["project"]["dependencies"]

    # Filter out Windows‑excluded dependencies
    filtered = [
        d for d in deps
        if 'platform_system != "Windows"' not in d
    ]

    return filtered

def write_requirements(deps, output_path):
    output_path = Path(output_path)

    with open(output_path, "w") as f:
        for d in deps:
            f.write(d.strip() + "\n")

    print(f"✔ requirements written to: {output_path}")

if __name__ == "__main__":
    # Default output file
    output = "requirements.txt"

    # If user provided a filename, use it
    if len(sys.argv) > 1:
        output = sys.argv[1]

    deps = load_dependencies()
    write_requirements(deps, output)   