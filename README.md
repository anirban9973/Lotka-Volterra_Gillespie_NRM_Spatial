# Lotka-Volterra Stochastic Model — Spatial Gillespie / NRM

Stochastic spatial simulation of the **Lotka-Volterra predator-prey model** on a 1D periodic lattice using the **Next Reaction Method (NRM)**. The goal is to compute time-integrated spatial density profiles for ensemble-averaged structure factor / power spectrum analysis at ω=0.

## Model

Two species — prey (P) and predator (H) — interact on a lattice of L sites with periodic boundary conditions. Each site hosts 10 possible events:

| # | Event | Propensity |
|---|-------|-----------|
| 1 | Predator diffusion (linear) | `ν₁H · H` |
| 2 | Predator diffusion (nonlinear) | `ν₂H · H(H-1)/V` |
| 3 | Prey diffusion (linear) | `μ₁P · P` |
| 4 | Prey diffusion (nonlinear) | `μ₂P · P·H/V` |
| 5 | Prey birth | `bP · P` |
| 6 | Successful predation: P + H → 2H | `ps · P·H/V` |
| 7 | Failed predation: P + H → H | `pf · P·H/V` |
| 8 | Predator linear death | `dH · H` |
| 9 | Prey linear death | `dP · P` |
| 10 | Prey competition: 2P → P | `cP · P(P-1)/V` |

The mean-field equations are:

```
dρP/dt = (bP - dP)·ρP - (ps + pf)·ρP·ρH - cP·ρP²
dρH/dt =  ps·ρP·ρH - dH·ρH
```

Diffusion events move a particle to a randomly chosen nearest neighbour. The NRM uses a min-heap of per-site firing times for O(log L) event selection.

Initial conditions are set to the mean-field steady state:

```
ρP* = dH / ps
ρH* = (bP - dP - cP·ρP*) / (ps + pf)
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
bP   5.0    # prey birth rate
ps   1.0    # successful predation rate (P + H -> 2H)
pf   0.0    # failed predation rate    (P + H -> H)
dH   0.1    # predator linear death rate
dP   0.5    # prey linear death rate
cP   1.0    # prey intraspecific competition rate

# Diffusion (bare multipliers — scaled by z in code)
z    2.0    # coordination number (fixed: 2 for 1D lattice)
mu1P 0.0   # prey linear diffusion
mu2P 0.0   # prey nonlinear diffusion
nu1H 0.0   # predator linear diffusion
nu2H 0.0   # predator nonlinear diffusion

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

One HDF5 file per array job: `output_job<J>.h5`

| Dataset | Shape | Description |
|---------|-------|-------------|
| `prey` | `(2400, L)` | time-integrated prey density per realization |
| `predator` | `(2400, L)` | time-integrated predator density per realization |
| `seeds` | `(2400,)` | unique seed (global realization identifier) |

Results are written **after all realizations in a job complete** — each thread writes its block of rows atomically via an OpenMP critical section.

## File Structure

```
.
├── Lotka_Volterra_stochastic_model.cpp    # main simulation (OOP + OpenMP)
├── nrm_heap_header.h                      # NRM heap data structures
├── input.dat                              # runtime parameters
├── Makefile                               # build system (spack-aware)
├── executable_prep.sh                     # local compile script
├── job.sh                                 # SLURM array job script
└── README.md
```

## References

- Lotka, A.J. (1925). *Elements of Physical Biology*. Williams & Wilkins.
- Volterra, V. (1926). Fluctuations in the abundance of a species considered mathematically. *Nature*, 118, 558–560.
- Gibson, M.A. & Bruck, J. (2000). Efficient exact stochastic simulation of chemical systems with many species and many channels. *J. Phys. Chem. A*, 104, 1876–1889.
