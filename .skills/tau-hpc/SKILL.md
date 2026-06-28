---
name: tau-hpc
description: Connect to TAU HPC servers for experiments. Supports Power SLURM (slurmlogin.tau.ac.il), CS SLURM (slurm-client.cs.tau.ac.il) for TML/APDL course jobs, and direct SSH (rack-mad-01.cs.tau.ac.il) for MASS. Use when user wants to run experiments, submit jobs, connect to TAU VPN, use course storage, or SSH to TAU servers.
---

# TAU HPC Servers

When invoked, **always ask the user for** OTP (for VPN) and which server/course.

| Server | Host | Purpose | Workdir | Shell |
|--------|------|---------|---------|-------|
| **slurmlogin** | `slurmlogin.tau.ac.il` | GPU batch jobs | `/scratch300/galaharoni` | bash |
| **rack-mad-01** | `rack-mad-01.cs.tau.ac.il` | MASS course | regular home | tcsh |
| **slurm-client** | `slurm-client.cs.tau.ac.il` | CS SLURM: TML/APDL course jobs | TML: `/home/sharifm/teaching/tml-0368-4075/galaharoni`; APDL: `/home/yandex/APDL2526a/galaharoni` | tcsh |

**Username**: `galaharoni` | **Credentials**: `$TAU_USERNAME` / `$TAU_PASSWORD` env vars | **Docs**: Power docs: https://hpcguide.tau.ac.il/; CS SLURM docs: https://www.cs.tau.ac.il/system/slurm

**Caveats**:
- **slurmlogin**: Default home doesn't exist — always `export HOME=/scratch300/galaharoni`
- **slurmlogin account**: Use Power Slurm account `gpu-tad-wolf_v2`. It is the verified default account for `galaharoni`.
- **slurmlogin uv**: `uv` is user-managed in `/scratch300/galaharoni/.local/bin/uv` (updated and verified `uv 0.11.25` on 2026-06-28), not a system install. In every interactive SSH command and Slurm job, set `HOME=/scratch300/galaharoni` first, then set `PATH=$HOME/.local/bin:$PATH`, before calling `uv`.
- **slurmlogin VPN**: Do not disconnect the TAU VPN unless the user explicitly asks or cleanup is required for a failed/stale session.
- **rack-mad-01**: Has fail2ban — NEVER retry wrong passwords (locked out ~30 min)
- **tcsh servers** (`rack-mad-01`, `slurm-client`): Wrap commands in `/bin/bash -lc '...'`
- **slurm-client**: `slurm-client.cs.tau.ac.il` may route to different `c-00x` client nodes with different host keys. If known-host checks block automation, use `-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no` for that command.
- **TML on slurm-client**: Regular CS home quota may be full. Use `/home/sharifm/teaching/tml-0368-4075/galaharoni` for environments, data, logs, caches, and temp files. In jobs, set `HOME`, `MPLCONFIGDIR`, `XDG_CACHE_HOME`, and `TMPDIR` into that course directory.
- No `rsync` on cluster — use `scp` with tar (exclude `.venv`, `__pycache__`, `.git`)

---

## VPN

```bash
export TAU_USERNAME='galaharoni'
export TAU_PASSWORD='<password>'
# If the password contains '$', prefer single quotes as above.
# If you must use double quotes, escape each '$' as '\$'.
uv run $HOME/.copilot/skills/tau-hpc/scripts/vpn-connect.py "$TAU_USERNAME" "$TAU_PASSWORD" <OTP>
```

Pass the OTP as a literal positional argument. Do **not** use a same-line assignment
and then reference it in the same command, because the shell expands `$TAU_OTP`
before applying `TAU_OTP=...`:

```bash
# Wrong: "$TAU_OTP" expands before TAU_OTP=043900 is applied.
TAU_OTP=043900 uv run $HOME/.copilot/skills/tau-hpc/scripts/vpn-connect.py "$TAU_USERNAME" "$TAU_PASSWORD" "$TAU_OTP"

# Correct:
uv run $HOME/.copilot/skills/tau-hpc/scripts/vpn-connect.py "$TAU_USERNAME" "$TAU_PASSWORD" 043900
```

**Split tunnel (default)**:
- `vpn-connect.py` uses `scripts/tau-vpnc-split.sh` via `openconnect --script`.
- Only TAU routes go through VPN: `132.66.0.0/16`, `132.67.0.0/16`.
- Default internet traffic stays on VM NIC (`ens4`) to keep Tailscale direct.

**Adding a new TAU server**:
- If host IP is in `132.66/16` or `132.67/16`, no change needed.
- Otherwise either add a new `add_split_route` in `scripts/tau-vpnc-split.sh`, or set `TAU_EXTRA_VPN_HOSTS="<hostname>"` before connecting.

**Quick verify**:
- `ip route get slurm-client.cs.tau.ac.il` should resolve to `dev tun0`.
- `tailscale status` should show active peers as `direct ...` (not DERP).
- TAU's SAML/Google Authenticator flow can take more than a minute after OTP submission before the GlobalProtect callback arrives; don't assume the helper is stuck unless it reports failure.

---

## SSH

```bash
# slurmlogin (bash, always set HOME)
SSHPASS="$TAU_PASSWORD" sshpass -e ssh -o StrictHostKeyChecking=no galaharoni@slurmlogin.tau.ac.il "
export HOME=/scratch300/galaharoni PATH=\$HOME/.local/bin:\$PATH
cd \$HOME
<commands>
"

# rack-mad-01 — MASS (tcsh → bash)
SSHPASS="$TAU_PASSWORD" sshpass -e ssh -o StrictHostKeyChecking=no \
  galaharoni@rack-mad-01.cs.tau.ac.il "/bin/bash -lc '<commands>'"

# slurm-client — APDL (tcsh → bash)
SSHPASS="$TAU_PASSWORD" sshpass -e ssh -o StrictHostKeyChecking=no \
  galaharoni@slurm-client.cs.tau.ac.il "/bin/bash -lc '
cd /home/yandex/APDL2526a/galaharoni
<commands>
'"

# slurm-client — TML (tcsh → bash; transient host keys possible)
SSHPASS="$TAU_PASSWORD" sshpass -e ssh \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  galaharoni@slurm-client.cs.tau.ac.il "/bin/bash -lc '
cd /home/sharifm/teaching/tml-0368-4075/galaharoni
<commands>
'"
```

---

## SLURM Partitions

### slurmlogin (account: `gpu-tad-wolf_v2`)

| Partition | QOS | GPUs |
|-----------|-----|------|
| `gpu-tad-pool` | `owner` | H100, A100 (priority; verified real A100 job under `gpu-tad-wolf_v2`) |
| `gpu-general-pool` | `public` | H100, H200, A100, L40S, A6000, A5000, RTX 6000, V100 |
| `power-general-public-pool` | `public` | CPU-only |

Verified on 2026-06-28:
- `gpu-tad-wolf_v2` is the default and only Power Slurm association for `galaharoni`.
- A real `gpu-tad-pool` owner job with `--gres=gpu:A100:1` completed under `gpu-tad-wolf_v2` and saw `NVIDIA A100-SXM4-80GB`.
- `power-general-shared-pool` may show GPU nodes in `sinfo`, but Slurm rejects GPU submissions there as a non-GPU partition.
- Public GPU jobs on `gpu-general-pool` are accepted but can have long backfill delays; prefer `gpu-tad-pool` with owner QOS for real work.

Typical owner GPU request:

```bash
#SBATCH --account=gpu-tad-wolf_v2
#SBATCH --partition=gpu-tad-pool
#SBATCH --qos=owner
#SBATCH --gres=gpu:A100:1
```

### slurm-client

Verified accounts for `galaharoni`: `gpu-students` on `studentkillable`, `gpu-research` on `killable`.

| Partition | Time limit | GPUs |
|-----------|------------|------|
| `killable` (default) | 1 day | L40S, A6000, RTX 3090/2080, A5000, V100 |
| `gpu-h100-killable` | 1 day | H100 |
| `studentkillable` | 1 day | TITAN, RTX 2080 |
| `cpu-killable` | 5 days | CPU-only |

---

## SLURM Job Template (slurmlogin)

```bash
cat > job.sbatch << 'EOF'
#!/bin/bash
#SBATCH --job-name=my-job
#SBATCH --account=gpu-tad-wolf_v2
#SBATCH --partition=gpu-tad-pool
#SBATCH --qos=owner
#SBATCH --gres=gpu:A100:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --output=/scratch300/galaharoni/job_%j.out

export HOME=/scratch300/galaharoni
export PATH=$HOME/.local/bin:$PATH
export UV_CACHE_DIR=$HOME/.cache/uv
cd /scratch300/galaharoni/your-repo

command -v uv
uv --version
uv sync
uv run python -u your_script.py
EOF

sbatch job.sbatch
```

## TML Job Template (slurm-client)

Use the course storage from the professor's email. Install course-specific Python
environments under this directory, not under regular CS home.

```bash
COURSE=/home/sharifm/teaching/tml-0368-4075/galaharoni

# One-time environment setup, if no suitable environment exists.
cd "$COURSE"
wget -q -O miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-py310_24.7.1-0-Linux-x86_64.sh
bash miniconda.sh -b -p "$COURSE/miniconda3"
source "$COURSE/miniconda3/etc/profile.d/conda.sh"
conda create -y -p "$COURSE/hw1_env" python=3.10 pip
"$COURSE/hw1_env/bin/python" -m pip install -r "$COURSE/path/to/requirements.txt" "pandas<2" "scipy<1.12"
```

```bash
cat > "$COURSE/job.sbatch" << 'EOF'
#!/bin/bash
#SBATCH --job-name=tml-job
#SBATCH --partition=studentkillable
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=/home/sharifm/teaching/tml-0368-4075/galaharoni/job_%j.out

set -euo pipefail
export COURSE_DIR=/home/sharifm/teaching/tml-0368-4075/galaharoni
export HOME=$COURSE_DIR
export MPLBACKEND=Agg
export MPLCONFIGDIR=$COURSE_DIR/.cache/matplotlib
export XDG_CACHE_HOME=$COURSE_DIR/.cache
export TMPDIR=$COURSE_DIR/tmp
mkdir -p "$MPLCONFIGDIR" "$TMPDIR"

source "$COURSE_DIR/miniconda3/etc/profile.d/conda.sh"
conda activate "$COURSE_DIR/hw1_env"
cd "$COURSE_DIR/your-workdir"

python - <<'PY'
import torch
print("cuda_available", torch.cuda.is_available())
if torch.cuda.is_available():
    print("cuda_device_name", torch.cuda.get_device_name(0))
PY

python -u your_script.py
EOF

SSHPASS="$TAU_PASSWORD" sshpass -e ssh \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  galaharoni@slurm-client.cs.tau.ac.il "/bin/bash -lc 'sbatch $COURSE/job.sbatch'"
```
