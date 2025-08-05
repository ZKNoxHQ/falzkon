# FALZKON

FALZKON gather experimentations around falcon modification for ZKVM systems.

zk Friendly FAlcon implementation 

[Falcon signature scheme](https://falcon-sign.info/) is a post-quantum digital signature algorithm. 
This repo provides:

* on-chain [contracts](https://github.com/falzkon/cairo)

## INSTALLATION

- It is required to install [Starknet development environment](https://docs.starknet.io/guides/quickstart/environment-setup/) to run the contracts.


* **Tests:**
    ```bash
    scarb test
    ```

## BENCHMARKS

### NTT

| Function                   | Description               | gas cost | Tests Status |
|------------------------|---------------------|---------------------|---------------------|
| zntt_unroll_1x9      | ZKNOX NTT       | 7.6M | :white_check_mark:|
| ntt       | Starkware      | 36.6 M | :white_check_mark:|

zntt_unroll_1x9 benefits from [ETHFALCON solidity](https://github.com/ZKNoxHQ/ETHFALCON/tree/main/src) return of experience, with the following optimizations:

- use of Longa iterative NTT

- all code being unrolled

- only one final modular reduction instead of each level of the ntt


### HashToPoint


| Function                   | Description               | gas cost | Tests Status |
|------------------------|---------------------|---------------------|---------------------|
| HashToPoint_RIP      | ZKNOX NTT       | 71.1M | :white_check_mark:|
| HashToPoint_blake2s      | ZKNOX NTT       | WIP | WIP |

| HashToPoint       | Starkware      | Not implemented |  X |
