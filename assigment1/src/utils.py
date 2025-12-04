from pathlib import Path


def find_root_project():
    current_path = Path.cwd()

    for path in [current_path] + list(current_path.parents):
        
        if (path / ".git").exists():
            return str(path)
            
    print("ERROR: not a git repo :(")
    return None

REPO_ROOT = find_root_project()
PROJECT_ROOT = f"{REPO_ROOT}/assigment1"
