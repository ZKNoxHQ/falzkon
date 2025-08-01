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
| zntt_unroll_1x9      | ZKNOX NTT       | 7.6M | WIP|
| ntt       | Starkware      | 38.6 M | :white_check_mark:|

### HashToPoint

