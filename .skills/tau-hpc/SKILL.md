---
name: tau-hpc
description: Connect to TAU HPC servers for experiments. Supports SLURM cluster (slurmlogin.tau.ac.il) for GPU batch jobs, direct SSH (rack-mad-01.cs.tau.ac.il) for MASS course, and SLURM client (slurm-client.cs.tau.ac.il) for APDL course. Use when user wants to run experiments, submit jobs, connect to TAU VPN, or SSH to TAU servers.
---

# TAU HPC Servers

When invoked, **always ask the user for** OTP (for VPN) and which server/course.

| Server | Host | Purpose | Workdir | Shell |
|--------|------|---------|---------|-------|
| **slurmlogin** | `slurmlogin.tau.ac.il` | GPU batch jobs | `/scratch300/galaharoni` | bash |
| **rack-mad-01** | `rack-mad-01.cs.tau.ac.il` | MASS course | regular home | tcsh |
| **slurm-client** | `slurm-client.cs.tau.ac.il` | APDL course | `/home/yandex/APDL2526a/galaharoni` | tcsh |

**Username**: `galaharoni` | **Credentials**: `$TAU_USERNAME` / `$TAU_PASSWORD` env vars (single-quote passwords) | **Docs**: https://hpcguide.tau.ac.il/

**Caveats**:
- **slurmlogin**: Default home doesn't exist — always `export HOME=/scratch300/galaharoni`
- **rack-mad-01**: Has fail2ban — NEVER retry wrong passwords (locked out ~30 min)
- **tcsh servers** (`rack-mad-01`, `slurm-client`): Wrap commands in `/bin/bash -c '...'`
- No `rsync` on cluster — use `scp` with tar (exclude `.venv`, `__pycache__`, `.git`)

---

## VPN

```bash
export TAU_USERNAME=galaharoni TAU_PASSWORD='<password>'
uv run $HOME/dotfiles/.skills/tau-hpc/scripts/vpn-connect.py $TAU_USERNAME $TAU_PASSWORD <OTP>
```

---

## SSH

```bash
SSH_CMD="sshpass -p \$TAU_PASSWORD ssh -o StrictHostKeyChecking=no"

# slurmlogin (bash, always set HOME)
$SSH_CMD galaharoni@slurmlogin.tau.ac.il "
export HOME=/scratch300/galaharoni PATH=\$HOME/.local/bin:\$PATH
cd \$HOME
<commands>
"

# rack-mad-01 — MASS (tcsh → bash)
$SSH_CMD galaharoni@rack-mad-01.cs.tau.ac.il "/bin/bash -c '<commands>'"

# slurm-client — APDL (tcsh → bash)
$SSH_CMD galaharoni@slurm-client.cs.tau.ac.il "/bin/bash -c '
cd /home/yandex/APDL2526a/galaharoni
<commands>
'"
```

---

## SLURM Partitions

### slurmlogin (account: `gpu-tad-users_v2`)

| Partition | QOS | GPUs |
|-----------|-----|------|
| `gpu-tad-pool` | `owner` | H100, A100 (priority) |
| `gpu-general-pool` | `public` | H100, H200, A100, L40S, A6000, V100 |
| `power-general-public-pool` | `public` | CPU-only |

### slurm-client

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
