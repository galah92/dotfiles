#!/bin/bash
#SBATCH --job-name=gpu-job
#SBATCH --partition=gpu-tad-pool
#SBATCH --qos=owner
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=/scratch300/galaharoni/job_%j.out

# -u: unbuffered stdout so logs appear in real-time
uv run python -u "$@"
