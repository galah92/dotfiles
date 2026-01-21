# TAU SLURM HPC Cluster

SLURM-managed HPC cluster with GPU nodes for batch job submission.

| Property | Value |
|----------|-------|
| **Host** | `slurmlogin.tau.ac.il` |
| **Username** | `galaharoni` |
| **Account** | `gpu-tad-users_v2` |
| **Working directory** | `/scratch300/galaharoni` |
| **Docs** | https://hpcguide.tau.ac.il/ |

**Important**: The default home directory (`/a/home/cc/students/cs/galaharoni`) doesn't exist. Always use `/scratch300/galaharoni` and set `HOME` accordingly.

---

## Quick Start (For AI Agents)

### 1. Connect VPN

```bash
# Set credentials
export TAU_USERNAME=galaharoni
export TAU_PASSWORD=<password>

# Get OTP from user, then connect
cd ~/dotfiles/.tau && python3 vpn-connect.py $TAU_USERNAME $TAU_PASSWORD <OTP>

# Verify connection
ip addr show tun0  # Should show 10.x.x.x address
pgrep openconnect  # Should show running process
```

### 2. SSH to Cluster

```bash
# Run command on cluster (sets HOME correctly)
sshpass -p "$TAU_PASSWORD" ssh -o StrictHostKeyChecking=no galaharoni@slurmlogin.tau.ac.il "
export HOME=/scratch300/galaharoni
cd \$HOME
<your commands here>
"
```

### 3. Submit GPU Job

```bash
sshpass -p "$TAU_PASSWORD" ssh -o StrictHostKeyChecking=no galaharoni@slurmlogin.tau.ac.il "
export HOME=/scratch300/galaharoni
cd /scratch300/galaharoni/your-repo

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
export PATH=\$HOME/.local/bin:\$PATH
cd /scratch300/galaharoni/your-repo

uv sync
uv run python -u your_script.py
EOF

sbatch job.sbatch
squeue -u galaharoni
"
```

### 4. Check Job Output

```bash
sshpass -p "$TAU_PASSWORD" ssh -o StrictHostKeyChecking=no galaharoni@slurmlogin.tau.ac.il "
tail -50 /scratch300/galaharoni/job_<JOBID>.out
"
```

---

## VPN Connection (Detailed)

TAU uses Palo Alto GlobalProtect VPN with SAML authentication.

### Requirements

```bash
sudo apt install openconnect sshpass
pip install playwright && playwright install chromium

# Install gpclient 2.5.x from https://github.com/yuezk/GlobalProtect-openconnect/releases
sudo apt install ./globalprotect-openconnect_*.deb
```

### How vpn-connect.py Works

1. **Starts gpclient** in gateway mode with `--browser remote`
2. **gpclient creates a local auth server** (e.g., `http://10.x.x.x:PORT/UUID`)
3. **Playwright opens the auth URL** which redirects to TAU's SAML IdP
4. **Fills credentials and OTP** automatically
5. **Extracts callback URL** from the "click here" link on the auth complete page
6. **Decodes the cookie** from the base64-encoded callback data
7. **Connects via openconnect** with `--background` flag (keeps VPN alive)

### Usage

```bash
# With all arguments
./vpn-connect.py galaharoni <password> <OTP>

# With environment variables
export TAU_USERNAME=galaharoni
export TAU_PASSWORD=<password>
./vpn-connect.py <OTP>
```

### Verify Connection

```bash
# Check tunnel interface
ip addr show tun0

# Check openconnect process
pgrep -a openconnect

# Test SSH
sshpass -p "$TAU_PASSWORD" ssh galaharoni@slurmlogin.tau.ac.il hostname
```

### Disconnect

```bash
sudo pkill openconnect
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| "No auth URL" | gpclient may have crashed; try again |
| "No callback" | OTP expired (they're short-lived); get fresh OTP |
| "No tun0 interface" | openconnect failed; check sudo permissions |
| SSH timeout | VPN not connected; re-run vpn-connect.py |
| HIP report warning | Can be ignored; VPN works without it |

---

## SSH Setup

SSH keys don't work because the home directory doesn't exist. Use `sshpass`.

### Interactive Session

Add to `~/.ssh/config`:

```
Host tau
    HostName slurmlogin.tau.ac.il
    User galaharoni
    RequestTTY yes
    RemoteCommand HOME=/scratch300/galaharoni exec bash -l
```

Then: `sshpass -p "$TAU_PASSWORD" ssh tau`

### Non-Interactive Commands

Always set HOME explicitly:

```bash
sshpass -p "$TAU_PASSWORD" ssh -o StrictHostKeyChecking=no galaharoni@slurmlogin.tau.ac.il "
export HOME=/scratch300/galaharoni
export PATH=\$HOME/.local/bin:\$PATH
cd \$HOME
<commands>
"
```

---

## Copying Files to Cluster

`rsync` is not available on this VM. Use `scp` with tar:

```bash
# Create tarball (exclude large directories)
cd /path/to/repo
tar czf /tmp/repo.tar.gz --exclude='.venv' --exclude='__pycache__' --exclude='.git' --exclude='results' .

# Copy to cluster
sshpass -p "$TAU_PASSWORD" scp -o StrictHostKeyChecking=no /tmp/repo.tar.gz galaharoni@slurmlogin.tau.ac.il:/scratch300/galaharoni/

# Extract on cluster
sshpass -p "$TAU_PASSWORD" ssh -o StrictHostKeyChecking=no galaharoni@slurmlogin.tau.ac.il "
export HOME=/scratch300/galaharoni
cd /scratch300/galaharoni
mkdir -p my-repo && cd my-repo
tar xzf ../repo.tar.gz
"
```

---

## GPU Resources

| Partition | QOS | GPUs | Notes |
|-----------|-----|------|-------|
| `gpu-tad-pool` | `owner` | 8x H100, 32x A100 | Priority access, may have queue |
| `gpu-general-pool` | `public` | ~117 GPUs (H100, A100, L40S, RTX A6000) | More availability |

### Check Available Resources

```bash
sinfo -p gpu-general-pool -o "%P %a %D %t %G"
```

---

## Job Submission

### Basic GPU Job

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
cd /scratch300/galaharoni/my-repo

echo "Job started at $(date)"
echo "Node: $(hostname)"
nvidia-smi --query-gpu=name,memory.total --format=csv

uv sync
uv run python -u my_script.py

echo "Job completed at $(date)"
EOF

sbatch job.sbatch
```

### Job Management

```bash
squeue -u galaharoni           # Check queue
scancel <JOBID>                # Cancel job
sacct -j <JOBID>               # Job history
tail -f /scratch300/galaharoni/job_<JOBID>.out  # Watch output
```

### Tools Available

- **uv**: `/scratch300/galaharoni/.local/bin/uv` (Python package manager)
- **gh**: GitHub CLI (in .local/bin)

---

## Complete Example: Run Experiment

```bash
# 1. Connect VPN (need fresh OTP from user)
export TAU_USERNAME=galaharoni
export TAU_PASSWORD=<password>
cd ~/dotfiles/.tau && python3 vpn-connect.py $TAU_USERNAME $TAU_PASSWORD <OTP>

# 2. Copy code to cluster
cd ~/my-project
tar czf /tmp/repo.tar.gz --exclude='.venv' --exclude='__pycache__' --exclude='.git' .
sshpass -p "$TAU_PASSWORD" scp /tmp/repo.tar.gz galaharoni@slurmlogin.tau.ac.il:/scratch300/galaharoni/

# 3. Extract and submit job
sshpass -p "$TAU_PASSWORD" ssh galaharoni@slurmlogin.tau.ac.il "
export HOME=/scratch300/galaharoni
cd \$HOME
rm -rf my-project && mkdir my-project && cd my-project
tar xzf ../repo.tar.gz

cat > job.sbatch << 'SBATCH'
#!/bin/bash
#SBATCH --job-name=experiment
#SBATCH --partition=gpu-general-pool
#SBATCH --qos=public
#SBATCH --gres=gpu:1
#SBATCH --mem=32G
#SBATCH --time=00:30:00
#SBATCH --output=/scratch300/galaharoni/job_%j.out

export HOME=/scratch300/galaharoni
export PATH=\$HOME/.local/bin:\$PATH
cd /scratch300/galaharoni/my-project

uv sync
uv run python -u experiment.py
SBATCH

sbatch job.sbatch
squeue -u galaharoni
"

# 4. Monitor job
sshpass -p "$TAU_PASSWORD" ssh galaharoni@slurmlogin.tau.ac.il "
squeue -u galaharoni
tail -30 /scratch300/galaharoni/job_*.out 2>/dev/null | tail -30
"
```

---

## References

- [TAU HPC Guide](https://hpcguide.tau.ac.il/)
- [GlobalProtect-openconnect](https://github.com/yuezk/GlobalProtect-openconnect)
- [TAU VPN Guide](https://hpcguide.tau.ac.il/index.php?title=Palo_Alto_VPN_for_linux)
