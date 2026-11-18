# dotfiles

Install: `stow -R .`

The native Claude Code installer enables background updates.

```sh
curl -fsSL https://claude.ai/install.sh | bash -s latest
```

Install the standalone Codex CLI and run `codex update` when you want to upgrade it.

```sh
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

Notes:

- `.stowrc` uses `--no-folding` to avoid directory folding (it links files inside directories instead of replacing whole directories with one symlink).
- `.stowrc` uses `--ignore=^[^.][^/]*$`, which ignores any top-level path that does not start with `.`.
