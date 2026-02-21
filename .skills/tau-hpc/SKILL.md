---
name: tau-hpc
description: Connect to TAU HPC servers for experiments. Supports SLURM cluster (slurmlogin.tau.ac.il) for GPU batch jobs and direct SSH (rack-mad-01.cs.tau.ac.il) for CPU benchmarks. Use when user wants to run experiments, submit jobs, connect to TAU VPN, or SSH to TAU servers.
---

# TAU HPC Servers

| Property | Value |
|----------|-------|
| **SLURM Host** | `slurmlogin.tau.ac.il` |
| **Direct SSH Host** | `rack-mad-01.cs.tau.ac.il` |
| **Username** | `galaharoni` |
| **Account** | `gpu-tad-users_v2` |
| **Working directory (SLURM)** | `/scratch300/galaharoni` |
| **Docs** | https://hpcguide.tau.ac.il/ |

**Credentials**: `$TAU_USERNAME` / `$TAU_PASSWORD` env vars. Single-quote passwords with special chars.

**SLURM HOME caveat**: Default home doesn't exist. Always `export HOME=/scratch300/galaharoni`. Does NOT apply to `rack-mad-01`.

**rack-mad-01 has fail2ban**: NEVER retry wrong passwords — locked out ~30 min.

No `rsync` on cluster — use `scp` with tar (exclude `.venv`, `__pycache__`, `.git`).

---

## VPN

```bash
export TAU_USERNAME=galaharoni
export TAU_PASSWORD='<password>'
uv run $HOME/dotfiles/.skills/tau-hpc/scripts/vpn-connect.py $TAU_USERNAME $TAU_PASSWORD <OTP>
```

First-time setup: `sudo apt install openconnect sshpass gpclient` and `uv run --with playwright playwright install chromium`.

---

## SSH

```bash
SSH_CMD="sshpass -p \$TAU_PASSWORD ssh -o StrictHostKeyChecking=no"

# SLURM (always set HOME)
$SSH_CMD galaharoni@slurmlogin.tau.ac.il "
export HOME=/scratch300/galaharoni PATH=\$HOME/.local/bin:\$PATH
cd \$HOME
<commands>
"

# rack-mad-01 (regular home, no override needed)
$SSH_CMD galaharoni@rack-mad-01.cs.tau.ac.il "<commands>"
```

---

## SLURM Jobs

| Partition | QOS | GPUs |
|-----------|-----|------|
| `gpu-tad-pool` | `owner` | 8x H100, 32x A100 (priority) |
| `gpu-general-pool` | `public` | ~117 GPUs (H100, A100, L40S, RTX A6000) |
| `power-general-public-pool` | `public` | CPU-only, 24+ cores |

```bash
cat > job.sbatch << 'EOF'
#!/bin/bash
#SBATCH --job-name=my-job
#SBATCH --partition=gpu-general-pool
#SBATCH --qos=public
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --output=/scratch300/galaharoni/job_%j.out

export HOME=/scratch300/galaharoni
export PATH=$HOME/.local/bin:$PATH
cd /scratch300/galaharoni/your-repo

uv sync
uv run python -u your_script.py
EOF

sbatch job.sbatch
```
