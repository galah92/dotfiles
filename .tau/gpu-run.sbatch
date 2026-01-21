#!/bin/bash
#SBATCH --job-name=gpu-job
#SBATCH --partition=gpu-general-pool
#SBATCH --qos=public
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --output=/scratch300/galaharoni/job_%j.out

# CRITICAL: Set HOME since default doesn't exist
export HOME=/scratch300/galaharoni
export PATH=$HOME/.local/bin:$PATH

echo "Job started at $(date)"
echo "Node: $(hostname)"
nvidia-smi --query-gpu=name,memory.total --format=csv

# Run command with unbuffered output
uv run python -u "$@"

echo "Job completed at $(date)"
