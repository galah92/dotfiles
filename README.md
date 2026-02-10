# dotfiles

Install/restow: `stow -R .`

Notes:

- `--no-folding` tells Stow to avoid directory folding (it links files inside directories instead of replacing whole directories with one symlink).
- `.stowrc` uses `--ignore=^[^.][^/]*$`, which ignores any top-level path that does not start with `.`.
