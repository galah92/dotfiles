# TAU SLURM HTC Cluster

SLURM-managed HPC cluster with GPU nodes for batch job submission.

- **Host**: `slurmlogin.tau.ac.il`
- **Username**: `galaharoni`
- **Account**: `gpu-tad-users_v2`
- **Working directory**: `/scratch300/galaharoni`
- **Docs**: https://hpcguide.tau.ac.il/
- **My tools**: `uv`, `gh` (installed in homedir)

## VPN Connection (Headless VM)

TAU uses Palo Alto GlobalProtect VPN with SAML authentication. Use `vpn-connect.py` to automate the connection from a headless VM.

### Requirements

```bash
sudo apt install openconnect
pip install playwright && playwright install chromium
```

Install `gpclient` from [GlobalProtect-openconnect](https://github.com/yuezk/GlobalProtect-openconnect):
```bash
# Download .deb from https://github.com/yuezk/GlobalProtect-openconnect/releases
sudo apt install ./globalprotect-openconnect_*.deb
```

### Usage

```bash
# With arguments
./vpn-connect.py USERNAME PASSWORD OTP

# With environment variables
export TAU_USERNAME=galaharoni
export TAU_PASSWORD=mypassword
./vpn-connect.py 123456  # just the OTP
```

### How It Works

Portal cookies don't work for gateway auth (error 512). The script:
1. Starts `gpclient --as-gateway --browser remote` to get an auth URL
2. Uses playwright to complete SAML auth (username, password, 2FA)
3. Captures the `globalprotectcallback://` response containing the gateway cookie
4. Connects via `openconnect` with the gateway cookie

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Error 512 "Invalid username or password" | Portal cookie used instead of gateway cookie - script handles this |
| Cookie expired | Cookies are short-lived; run script again with fresh OTP |
| HIP report warning | VPN works without HIP, some features may be limited |

### References

- [GlobalProtect-openconnect](https://github.com/yuezk/GlobalProtect-openconnect)
- [Issue #572: Portal cookie doesn't work on gateway](https://github.com/yuezk/GlobalProtect-openconnect/issues/572)
- [Discussion #453: Remote/headless authentication](https://github.com/yuezk/GlobalProtect-openconnect/discussions/453)
- [TAU VPN Guide](https://hpcguide.tau.ac.il/index.php?title=Palo_Alto_VPN_for_linux)

---

## SSH Setup

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

