# dotfiles

Install: `stow -R .`

Notes:

- `.stowrc` uses `--no-folding` to avoid directory folding (it links files inside directories instead of replacing whole directories with one symlink).
- `.stowrc` uses `--ignore=^[^.][^/]*$`, which ignores any top-level path that does not start with `.`.
