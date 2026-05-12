# Levin-Segel Stochastic Model — Spatial Gillespie / NRM

Stochastic spatial simulation of the **Levin-Segel predator-prey model** on a 1D periodic lattice using the **Next Reaction Method (NRM)**. The goal is to compute time-integrated spatial density profiles for ensemble-averaged structure factor / power spectrum analysis at ω=0, k=0.

## Model

Two species — prey (P) and predator (H) — interact on a lattice of L sites with periodic boundary conditions. Each site hosts 8 possible events:

| # | Event | Propensity |
|---|-------|-----------|
| 1 | Predator diffusion (normal) | `ν₁H · H` |
| 2 | Predator diffusion (coupled) | `ν₂H · H(H-1)/V` |
| 3 | Prey diffusion (normal) | `μ₁P · P` |
| 4 | Prey diffusion (coupled) | `μ₂P · P·H/V` |
| 5 | Prey birth (linear) | `b · P` |
| 6 | Prey birth (nonlinear) | `e · P(P-1)/V` |
| 7 | Predation | `p₁ · P·H/V` |
| 8 | Predator death (competition) | `d₂H · H(H-1)/V` |

Diffusion events move a particle to a randomly chosen nearest neighbour. The NRM uses a min-heap of per-site firing times for O(log L) event selection.

Initial conditions are set to the mean-field steady state:
```
ρP = b·d₂H / (p₁² - d₂H·e)
ρH = b·p₁  / (p₁² - d₂H·e)
```

## Dependencies

All dependencies are managed via [Spack](https://spack.io/):

| Package | Version |
|---------|---------|
| GCC (with OpenMP) | 11.5.0 |
| HDF5 (with MPI) | 1.14.6 |
| HighFive (header-only HDF5 C++ wrapper) | 2.10.1 |
| OpenMPI | 5.0.9 |

## Building

```bash
source ~/spack/share/spack/setup-env.sh
make clean && make
```

Or simply:

```bash
bash executable_prep.sh
```

The `Makefile` locates all spack packages automatically via `spack location -i <package>` — no manual path configuration needed.

## Configuration

All physics and job parameters are set in **`input.dat`** — no recompilation required:

```
# Lattice and volume
L                        128       # number of lattice sites
V                        100.0     # volume (controls particle number)

# Temporal settings
T_length                 32768     # simulation length after transient (2^15)
t_transient              1000.0    # burn-in time

# Reaction rates
b    0.5    # prey birth rate
e    0.5    # nonlinear prey birth rate
p1   1.0    # predation rate
p2   0.0    # (unused)
d1P  0.0    # (unused)
d2P  0.0    # (unused)
d1H  0.0    # (unused)
d2H  0.5    # predator death rate (competition)

# Diffusion (bare multipliers — scaled by z in code)
z    2.0    # diffusion prefactor
mu1P 1.0   # prey normal diffusion
mu2P 0.0   # prey coupled diffusion
nu1H 26.0  # predator normal diffusion
nu2H 0.0   # predator coupled diffusion

# Job configuration (n_threads must match --cpus-per-task in job.sh)
n_threads                24
realizations_per_thread  100
```

> **Note:** `mu1P`, `mu2P`, `nu1H`, `nu2H` are bare multipliers. The actual rates used in the simulation are `z × value`.

## Running

### Locally (single job)

```bash
./a.out <job_id>
```

### On SLURM cluster

```bash
sbatch job.sh
```

The array job runs **20 jobs × 24 threads × 100 realizations = 48,000 configurations** total. Seeds are globally unique: `seed = (job_id - 1) × 2400 + thread_id × 100 + local_idx`.

## Output

Each thread writes one HDF5 file: `output_job<J>_thread<T>.h5`

| Dataset | Shape | Description |
|---------|-------|-------------|
| `prey` | `(100, L)` | time-integrated prey density per realization |
| `predator` | `(100, L)` | time-integrated predator density per realization |
| `seeds` | `(100,)` | unique seed (global realization identifier) |

Results are written **immediately after each realization** — partial results are preserved if the job is interrupted.

## File Structure

```
.
├── Levin_Segel_stochastic_model.cpp   # main simulation (OOP + OpenMP)
├── nrm_heap_header.h                  # NRM heap data structures
├── input.dat                          # runtime parameters
├── Makefile                           # build system (spack-aware)
├── executable_prep.sh                 # local compile script
├── job.sh                             # SLURM array job script
└── README.md
```

## References

- Levin, S.A. & Segel, L.A. (1976). Hypothesis for origin of planktonic patchiness. *Nature*, 259, 659.
- Gibson, M.A. & Bruck, J. (2000). Efficient exact stochastic simulation of chemical systems with many species and many channels. *J. Phys. Chem. A*, 104, 1876–1889.
