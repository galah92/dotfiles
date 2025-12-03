# TAU SLURM HTC Cluster

SLURM-managed HPC cluster with GPU nodes for batch job submission.

- **Host**: `slurmlogin.tau.ac.il`
- **Username**: `galaharoni`
- **Account**: `gpu-tad-users_v2`
- **Working directory**: `/scratch300/galaharoni`
- **Docs**: https://hpcguide.tau.ac.il/
- **My tools**: `uv`, `gh` (installed in homedir)

## Setup

Requires VPN. SSH keys don't work (home directory doesn't exist), so use `sshpass`.

Add to `~/.ssh/config` for interactive sessions:

```
Host tau
    HostName slurmlogin.tau.ac.il
    User galaharoni
    RequestTTY yes
    RemoteCommand HOME=/scratch300/galaharoni exec bash -l
```

## Usage

```bash
sshpass -p "$TAU_PASSWORD" ssh tau          # Interactive
taussh squeue -u galaharoni                 # Run command (uses function in .shrc)
```

## GPU Resources

| Partition | QOS | GPUs |
|-----------|-----|------|
| `gpu-tad-pool` | `owner` | 8x H100, 32x A100 (priority) |
| `gpu-general-pool` | `public` | ~117 GPUs (H100, A100, L40S, RTX A6000, etc.) |

## Job Submission

`~/gpu-run.sbatch` runs any `uv run` command on a GPU node:

```bash
cd ~/sandalwood && sbatch ~/gpu-run.sbatch python -m sandalwood.flowmatching
```

