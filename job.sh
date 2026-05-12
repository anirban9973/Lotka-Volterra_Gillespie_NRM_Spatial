#!/bin/bash
#SBATCH --job-name=turing_model
#SBATCH --output=output_%A_%a.txt
#SBATCH --error=error_%A_%a.txt
#SBATCH --partition=edr1-al9_large
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --array=1-20

# Each job runs 2400 realizations via OpenMP (24 threads x 100 sequential each)
# Seeds: job 1 -> 0..2399, job 2 -> 2400..4799, ..., job 20 -> 45600..47999
./a.out $SLURM_ARRAY_TASK_ID
