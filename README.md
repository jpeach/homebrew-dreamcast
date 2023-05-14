# jpeach/dreamcast Homebrew tap

## How do I install these formulae?

`brew install jpeach/dreamcast/<formula>`

Or `brew tap jpeach/dreamcast` and then `brew install <formula>`.

## Documentation

This tap contains the following formulae:

| Name | Description |
| --- | --- |
| [cdirip](./Formula/cdirip.rb) | Program for extracting tracks from a CDI (DiscJuggler) image |
| [dc-toolchain-legacy](./Formula/dc-toolchain-legacy.rb) | Dreamcast compilation toolchain (legacy) |
| [dc-toolchain-stable](./Formula/dc-toolchain-stable.rb) | Dreamcast compilation toolchain (stable) |
| [dc-toolchain-testing](./Formula/dc-toolchain-testing.rb) | Dreamcast compilation toolchain (testing) |
| [dcload-serial](./Formula/dcload-serial.rb) | Host side of the dcload Sega Dreamcast serial loader |

For general Homebrew usage, see `brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).

## How to use the toolchain formulae

There are 3 `dc-toolchain` formulae, corresponding to the toolchain
build options implemented in KallistiOS. You can install all of them
simultaneously, then tell the KallistiOS build system which one to use
by sourcing the `kos.env` file in the corresponding formula prefix:

```bash
$ source $(brew --prefix dc-toolchain-testing)/kos.env
$ env | grep KOS
KOS_CC_PREFIX=sh-elf
KOS_CC_BASE=/usr/local/Cellar/dc-toolchain-testing/2022.05.10/sh-elf
```

