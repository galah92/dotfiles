---
name: tau-hpc
description: Connect to TAU HPC servers for experiments. Supports Power SLURM (slurmlogin.tau.ac.il), CS SLURM (slurm-client.cs.tau.ac.il) for TML/APDL course jobs, and direct SSH (rack-mad-01.cs.tau.ac.il) for MASS. Use when user wants to run experiments, submit jobs, connect to TAU VPN, use course storage, or SSH to TAU servers.
---

# TAU HPC

Identify the target from the request; ask only when it is genuinely ambiguous.

| Target | Host | Use | Working directory |
|---|---|---|---|
| Power SLURM | `slurmlogin.tau.ac.il` | GPU/CPU batch jobs | `/scratch300/galaharoni` |
| CS SLURM (TML) | `slurm-client.cs.tau.ac.il` | TML course jobs | `/home/sharifm/teaching/tml-0368-4075/galaharoni` |
| CS SLURM (APDL) | `slurm-client.cs.tau.ac.il` | APDL course jobs | `/home/yandex/APDL2526a/galaharoni` |
| MASS | `rack-mad-01.cs.tau.ac.il` | Direct SSH | regular home |

Username: `galaharoni`. Credentials come from `TAU_USERNAME` and
`TAU_PASSWORD`; never print them.

## Before network access

All Codex sessions on this VM share one TAU VPN tunnel. Do not disconnect it or
start a duplicate.

1. Run the helper once and trust its summary; do not repeat its `ip`, `pgrep`, or
   route checks unless diagnosing an inconsistency:

   ```bash
   python3 $HOME/.copilot/skills/tau-hpc/scripts/vpn-connect.py --status
   ```

   A nonzero exit simply means the VPN is not currently usable.

2. If connected, continue. If disconnected with `cached_reauth=yes`, try once:

   ```bash
   python3 $HOME/.copilot/skills/tau-hpc/scripts/vpn-connect.py --reuse
   ```

3. Ask for a fresh six-digit OTP only if the network operation is required and
   cached reuse is unavailable or rejected. Then connect with:

   ```bash
   uv run $HOME/.copilot/skills/tau-hpc/scripts/vpn-connect.py <OTP>
   ```

The helper reads the username/password from the environment. Pass the OTP as a
literal argument, not through a same-command environment assignment. It stores
only short-lived GlobalProtect cookies under `$XDG_RUNTIME_DIR/tau-vpn`, mode
`0600`, for up to 12 hours. Never expose that cache in output.

Do not force a disconnect to test reconnection. To refresh cached authentication
without replacing a healthy tunnel, use `uv run .../vpn-connect.py
--refresh-auth <OTP>` only when the user has supplied a fresh OTP.

The split tunnel routes only `132.66.0.0/16` and `132.67.0.0/16` through `tun0`.
Set `TAU_EXTRA_VPN_HOSTS=<hostname>` before connecting only for a TAU host outside
those networks.

## Power SLURM

Power uses bash, but its default home does not exist. Start every command and job
with:

```bash
export HOME=/scratch300/galaharoni
export PATH=$HOME/.local/bin:$PATH
cd "$HOME"
```

For a normal TAD A100 job, use exactly:

```bash
#SBATCH --account=gpu-tad-wolf_v2
#SBATCH --partition=gpu-tad-pool
#SBATCH --qos=0.25_656c_40g
#SBATCH --gres=gpu:A100:1
```

`gpu-tad-wolf_v2` is the verified account. The owner pool also has H100s. Use
`gpu-general-pool` with QOS `public` only when public capacity is intentional;
public jobs can wait much longer. `power-general-public-pool` is CPU-only.

Before a consequential submission, verify live availability and acceptance with
`sinfo`, `sacctmgr`, or `sbatch --test-only`; cluster policy can change.

Connect:

```bash
SSHPASS="$TAU_PASSWORD" sshpass -e ssh -o StrictHostKeyChecking=no \
  galaharoni@slurmlogin.tau.ac.il \
  'export HOME=/scratch300/galaharoni; export PATH=$HOME/.local/bin:$PATH; cd "$HOME"; <commands>'
```

The bundled `scripts/gpu-run.sbatch` is the small default A100 template. Copy it
and change only the job-specific resources and command.

## CS SLURM

The login shell is tcsh, so wrap remote commands in `/bin/bash -lc '...'`.
Different `slurm-client` nodes can present different host keys; for automation,
use both `StrictHostKeyChecking=no` and `UserKnownHostsFile=/dev/null`.

Verified associations:

| Account | Partition | Limit / GPUs |
|---|---|---|
| `gpu-students` | `studentkillable` | 1 day; TITAN, RTX 2080 |
| `gpu-research` | `killable` | 1 day; L40S, A6000, RTX 3090/2080, A5000, V100 |
| `gpu-research` | `gpu-h100-killable` | 1 day; H100 |
| CPU | `cpu-killable` | 5 days |

For TML, put environments, data, logs, caches, and temp files in the course
directory because the regular CS home quota may be full. In jobs, point `HOME`,
`MPLCONFIGDIR`, `XDG_CACHE_HOME`, and `TMPDIR` there.

```bash
SSHPASS="$TAU_PASSWORD" sshpass -e ssh \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  galaharoni@slurm-client.cs.tau.ac.il \
  "/bin/bash -lc 'cd <course-directory>; <commands>'"
```

## MASS

`rack-mad-01.cs.tau.ac.il` uses tcsh and fail2ban. Wrap commands with
`/bin/bash -lc`; never retry a password known to be wrong because lockouts last
about 30 minutes.

## File transfer and safety

- The clusters do not have `rsync`; transfer a tar archive with `scp`, excluding
  `.venv`, `__pycache__`, and `.git`.
- Inspect existing jobs and files before changing or deleting them.
- Do not submit jobs, cancel jobs, or overwrite remote data when the user asked
  only for inspection or advice.
- Do not disconnect the shared VPN unless the user explicitly asks or a failed
  connection attempt created a stale process that must be cleaned up.
