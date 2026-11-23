---
name: tau-hpc
description: Connect to TAU HPC servers for experiments. Supports Power SLURM (slurmlogin.tau.ac.il), CS SLURM (slurm-client.cs.tau.ac.il) for TML/APDL course jobs, and direct SSH (rack-mad-01.cs.tau.ac.il) for MASS. Use when user wants to run experiments, submit jobs, connect to TAU VPN, use course storage, or SSH to TAU servers.
---

# TAU HPC

Identify the target from the request; ask only when ambiguous.

| Target | Host | Use | Working directory |
|---|---|---|---|
| `power` (default) | `slurmlogin.tau.ac.il` | GPU/CPU batch jobs | `/scratch300/galaharoni` |
| `tml` | `slurm-client.cs.tau.ac.il` | TML course jobs | `/home/sharifm/teaching/tml-0368-4075/galaharoni` |
| `apdl` | `slurm-client.cs.tau.ac.il` | APDL course jobs | `/home/yandex/APDL2526a/galaharoni` |
| `mass` | `rack-mad-01.cs.tau.ac.il` | Direct SSH | regular home |

Credentials default to `TAU_USERNAME` / `TAU_PASSWORD` (automatic fallback: `~/.config/tau-hpc/env`). Never print credentials or cached cookies.

## VPN (shared across all sessions on this VM)

Never disconnect or duplicate a healthy shared tunnel. Run `vpn-connect.py --help` for full usage:

```bash
VPN="$HOME/dotfiles/.skills/tau-hpc/scripts/vpn-connect.py"
python3 "$VPN" --status    # trust this summary; nonzero = disconnected
python3 "$VPN" --reuse     # try once if disconnected with cached_reauth=yes
python3 "$VPN" <6-DIGIT-OTP>  # ask user for OTP only if needed
```

Split tunnel routes `132.66.0.0/16` and `132.67.0.0/16` via `tun0` (add `TAU_EXTRA_VPN_HOSTS=<host>` if needed). To refresh cookies without touching an active tunnel, use `--refresh-auth <OTP>`.

## Remote commands

Use `tau` (or `~/.local/bin/tau` if not on `PATH`; see `tau --help`). Power is the default target; use `-C <dir>` for working directory and `-c '...'` when shell syntax (pipes, `;`, redirects) is needed:

```bash
tau hostname
tau -C my-project -c 'squeue -u galaharoni; tail -5 job.log'
tau tml -C assignment-1 pwd
```

## Power SLURM

Default `$HOME` does not exist on Power—always start batch scripts with:

```bash
export HOME=/scratch300/galaharoni
export PATH=$HOME/.local/bin:$PATH
cd "$HOME"
```

Verified TAD A100 header (owner pool also has H100s; use `gpu-general-pool` + QOS `public` only intentionally):

```bash
#SBATCH --account=gpu-tad-wolf_v2
#SBATCH --partition=gpu-tad-pool
#SBATCH --qos=0.25_656c_40g
#SBATCH --gres=gpu:A100:1
```

Before consequential submissions, check live availability with `sinfo` / `sbatch --test-only`.

## CS SLURM & MASS

- **CS SLURM** (login shell is `tcsh`; `tau` wraps `bash`):
  - `gpu-students` / `studentkillable` (1d: TITAN, RTX 2080)
  - `gpu-research` / `killable` (1d: L40S, A6000, RTX 3090/2080, A5000, V100) or `gpu-h100-killable` (1d: H100)
  - CPU: `cpu-killable` (5d)
  - For TML, point `HOME`, `MPLCONFIGDIR`, `XDG_CACHE_HOME`, and `TMPDIR` into the course dir (home quota may be full).
- **MASS** (`rack-mad-01.cs.tau.ac.il`): fail2ban locks out ~30 min on wrong passwords—never retry a bad password.

## Safety & transfers

- No `rsync` on the clusters; transfer tarballs over `scp`/`ssh`, excluding `.venv`, `__pycache__`, and `.git`.
- Inspect remote jobs/files before modifying or deleting; never submit/cancel jobs when only asked to inspect or advise.
