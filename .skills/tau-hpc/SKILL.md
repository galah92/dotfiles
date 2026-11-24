---
name: tau-hpc
description: Connect to TAU HPC servers for experiments. Supports Power SLURM (slurmlogin.tau.ac.il), CS SLURM (slurm-client.cs.tau.ac.il) for research scratch and TML/APDL course jobs, and direct SSH (rack-mad-01.cs.tau.ac.il) for MASS. Use when user wants to run experiments, submit jobs, connect to TAU VPN, use cluster storage, or SSH to TAU servers.
---

# TAU HPC

Identify the target from the request; ask only when ambiguous.

| Target | Host | Use | Working directory |
|---|---|---|---|
| `power` (default) | `slurmlogin.tau.ac.il` | Non-preemptible A100/H100 jobs (4-GPU account cap) | `/scratch300/galaharoni` |
| `cs` | `slurm-client.cs.tau.ac.il` | High-throughput killable GPUs (16 TB scratch quota) | `/specific/scratches/scratch/galaharoni` |
| `tml` | `slurm-client.cs.tau.ac.il` | TML course storage | `/home/sharifm/teaching/tml-0368-4075/galaharoni` |
| `apdl` | `slurm-client.cs.tau.ac.il` | APDL course storage | `/home/yandex/APDL2526a/galaharoni` |
| `mass` | `rack-mad-01.cs.tau.ac.il` | Direct SSH | regular home |

Credentials default to `TAU_USERNAME` / `TAU_PASSWORD` (automatic fallback: `~/.config/tau-hpc/env`). Never print credentials or cached cookies.

## VPN (shared across all sessions on this VM)

Never disconnect or duplicate a healthy shared tunnel. Run `vpn-connect.py --help` for full usage:

```bash
VPN="$HOME/dotfiles/.skills/tau-hpc/scripts/vpn-connect.py"
python3 "$VPN" --status       # trust this summary; nonzero = disconnected
python3 "$VPN" --reuse        # try once if disconnected with cached_reauth=yes
python3 "$VPN" <6-DIGIT-OTP>  # ask user for OTP only if needed
```

Split tunnel routes `132.66.0.0/16` and `132.67.0.0/16` via `tun0` (add `TAU_EXTRA_VPN_HOSTS=<host>` if needed). To refresh cookies without touching an active tunnel, use `--refresh-auth <OTP>`.

## Remote commands

Use `tau` (or `~/.local/bin/tau` if not on `PATH`; see `tau --help`). Power is the default target; use `-C <dir>` for working directory and `-c '...'` for shell syntax (pipes, `;`, redirects, multiline):

```bash
tau hostname
tau cs -C my-project -c 'squeue -u galaharoni; tail -5 job.log'
tau -C my-project sbatch run.sbatch
```

## Power SLURM (`power`)

Default `$HOME` does not exist on Power—always start batch scripts with:

```bash
export HOME=/scratch300/galaharoni
export PATH=$HOME/.local/bin:$PATH
cd "$HOME"
```

Verified TAD A100 header (account cap is 4 GPUs via `MaxGRESPerAccount`; owner pool also has H100s; use `gpu-general-pool` + QOS `public` only intentionally):

```bash
#SBATCH --account=gpu-tad-wolf_v2
#SBATCH --partition=gpu-tad-pool
#SBATCH --qos=0.25_656c_40g
#SBATCH --gres=gpu:A100:1
```

Before consequential submissions, check live availability with `sinfo` / `sbatch --test-only`.

## CS SLURM (`cs`) & MASS

- **Storage (important):** CS `$HOME` has a tiny **6 GB quota**—never put datasets, venvs, or model caches there! Put project dirs under `/specific/scratches/scratch/galaharoni` (16 TB quota) and put `.venv`, `UV_CACHE_DIR`, and `HF_HOME` on node-local `/tmp/galaharoni-*` inside batch jobs (faster imports + zero quota pressure).
- **Partitions (verified via `sacctmgr`):**
  - `gpu-research` / `killable` (1d: L40S, A6000, RTX 3090/2080, A5000, V100) — always pass `#SBATCH --requeue` and write resumable checkpoints/done-markers.
  - `gpu-students` / `studentkillable` (1d: TITAN, RTX 2080).
  - *(No `cpu-killable` or `gpu-h100-killable` association currently exists; verify live with `sacctmgr -n -P show assoc where user=galaharoni format=Account,Partition` before assuming new ones.)*
- **Known bad CS nodes & quirks:**
  - Exclude broken GPU nodes: `#SBATCH --exclude=n-301,n-306,n-307` and fail fast on CUDA sanity (`python -c 'import torch; assert torch.cuda.is_available()'`).
  - Leave queue headroom when other workstreams are active (avoid hogging >40–50 queued jobs from one project).
  - On CS login nodes, `ls | wc -l` counts columns—use `find` to count files.
- **MASS** (`rack-mad-01.cs.tau.ac.il`): fail2ban locks out ~30 min on wrong passwords—never retry a bad password.

## Safety & transfers

- No `rsync` on the clusters; use `tau [target] put <local> <remote>` / `tau [target] get <remote> <local>` (wraps `scp -r -C` with compression and target default dirs; e.g. `tau cs put code.tgz myproj/`). Avoid transferring huge raw data over TAU VPN—download public datasets directly on the cluster. (`nova.cs.tau.ac.il` is also reachable as an alternate CS SFTP/SSH gateway.)
- Inspect remote jobs/files before modifying or deleting; never submit/cancel jobs when only asked to inspect or advise.
