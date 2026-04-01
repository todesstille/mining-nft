# AGENTS.md instructions for /home/baron/corecoin/cueswapV3

<INSTRUCTIONS>
## Skills
A skill is a set of local instructions to follow that is stored in a `SKILL.md` file. Below is the list of skills that can be used. Each entry includes a name, description, and file path so you can open the source for full instructions when using a specific skill.
### Available skills
- skill-creator: Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Codex's capabilities with specialized knowledge, workflows, or tool integrations. (file: /home/baron/.codex/skills/.system/skill-creator/SKILL.md)
- skill-installer: Install Codex skills into $CODEX_HOME/skills from a curated list or a GitHub repo path. Use when a user asks to list installable skills, install a curated skill, or install a skill from another repo (including private repos). (file: /home/baron/.codex/skills/.system/skill-installer/SKILL.md)
### How to use skills
- Discovery: The list above is the skills available in this session (name + description + file path). Skill bodies live on disk at the listed paths.
- Trigger rules: If the user names a skill (with `$SkillName` or plain text) OR the task clearly matches a skill's description shown above, you must use that skill for that turn. Multiple mentions mean use them all. Do not carry skills across turns unless re-mentioned.
- Missing/blocked: If a named skill isn't in the list or the path can't be read, say so briefly and continue with the best fallback.
- How to use a skill (progressive disclosure):
  1) After deciding to use a skill, open its `SKILL.md`. Read only enough to follow the workflow.
  2) If `SKILL.md` points to extra folders such as `references/`, load only the specific files needed for the request; don't bulk-load everything.
  3) If `scripts/` exist, prefer running or patching them instead of retyping large code blocks.
  4) If `assets/` or templates exist, reuse them instead of recreating from scratch.
- Coordination and sequencing:
  - If multiple skills apply, choose the minimal set that covers the request and state the order you'll use them.
  - Announce which skill(s) you're using and why (one short line). If you skip an obvious skill, say why.
- Context hygiene:
  - Keep context small: summarize long sections instead of pasting them; only load extra files when needed.
  - Avoid deep reference-chasing: prefer opening only files directly linked from `SKILL.md` unless you're blocked.
  - When variants exist (frameworks, providers, domains), pick only the relevant reference file(s) and note that choice.
- Safety and fallback: If a skill can't be applied cleanly (missing files, unclear instructions), state the issue, pick the next-best approach, and continue.
</INSTRUCTIONS>

# Project context

This repo is for smart contracts on a custom Core-like blockchain using the Ylem compiler.
Use the custom framework `spark` (a clone of Foundry/Forge). Build with `spark build`, and run tests with `spark test`.

## 1) Blockchain Parameters (Project-Independent)

Compiler and execution model:
- Pragmas should always be `pragma solidity ^1.1.2`.
- Addresses are 22 bytes.
- `keccak256` is implemented as SHA3-256 under the hood.
- As a result, all function selectors and hash-derived constants differ from Ethereum and must be recomputed for Core.

Cryptography differences vs Ethereum:
- `ecrecover` takes two arguments: `ecrecover(bytes32 hash, bytes signature)`.
- Failed recovery hard reverts (burns 63/64 gas), instead of returning `address(0)` or a random address.
- Signature length is fixed to 171 bytes; reject any other length.
- No exposed `(v, r, s)` tuple at Solidity level; signatures are passed as one blob.
- Signed-message prefix is `"\x19Core Signed Message:\n32"`.
- Typed-data hashing keeps EIP-712 framing: `keccak256("\x19\x01" || domainSeparator || structHash)`.

Address derivation model:
- A 32-byte secp256k1 private key derives a raw 20-byte EVM-style address.
- Core addresses are 22-byte ICAN addresses: network prefix + BCD checksum + raw address.
- Network prefixes used by `Checksum.toIcan`: mainnet `0xcb`, devin `0xab`.

RPC model:
- Core RPC uses `xcb_*` methods (example: `xcb_getBalance`), not `eth_*`.

## 2) Network Endpoints (Project-Independent)

Known node endpoints:
- Devin RPC: `https://xcbapi.corecoin.cc/`
- Devin RPC: `https://xcbapi-devin.coreblockchain.net/`
- Devin archive RPC: `https://xcbapi-arch-devin.coreblockchain.net/`
- Devin archive WS: `https://xcbws-arch-devin.coreblockchain.net/` (may not work)
- Mainnet RPC: `https://xcbapi.coreblockchain.net/`
- Mainnet archive RPC: `https://xcbapi-arch-mainnet.coreblockchain.net/`
- Mainnet archive WS: `https://xcbws-arch-mainnet.coreblockchain.net/` (may not work)

## 3) Core OpenZeppelin Compatibility (Project-Independent)

Core naming and library compatibility:
- OpenZeppelin `ECDSA` corresponds to `EDDSA` in this ecosystem.
- ERC standards are named `CRC*`:
  - `CRC20` / `CRC20Upgradeable`
  - `CRC721` / `CRC721Upgradeable`
  - `CRC1155` / `CRC1155Upgradeable`
- Use Core naming in file names, contract names, and revert reasons.

Core OpenZeppelin repositories (current):
- Non-upgradeable: `https://github.com/bchainhub/openzeppelin-contracts`
- Upgradeable: `https://github.com/bchainhub/openzeppelin-contracts-upgradeable`

Zero-address policy:
- Two zero-like values exist: `address(0)` and `Checksum.zeroAddress()`.
- For mint/burn style events with no real transfer, emit real zero: `address(0)`.
- Any non-zero address validation must reject both `address(0)` and `Checksum.zeroAddress()`.

ERC1967 slot constants (SHA3-256 minus 1):
- implementation: `0x169aa7877a62aec264f92a4c78812101abc42f65cbb20781a5cb4084c2d639d7`
- admin: `0x5846d050da0e75d43b6055ae3cd6c2c65e1941ccb45afff84b891ff0c7a8e50e`
- beacon: `0x79d0e26f0ed6a26bf96d37944c615e11aedbfafe56e064339e13dad9525cda31`
- rollback: `0x9918ff29762f88fdc924c0a0ba5589b288a6baef366b4981f9a6f4309baada55`

Common selector differences (SHA3-256 based):
- `admin()` selector: `0xeb8325fb`
- `implementation()` selector: `0xf5d97006`
- ERC1271 `isValidSignature(bytes32,bytes)` selector: `0x95f9a59b`
- ERC165 `supportsInterface(bytes4)` selector: `0x80ada41b`

## 4) Foxar / Spark Tooling (Project-Independent)

Tooling mapping:
- `forge` -> `spark`
- `cast` -> `probe`
- `anvil` -> `shuttle`
- `chisel` -> `pilot`
- `foundryup` -> `foxarup`

Foxar source of truth (for local debugging instead of web search):
- Repo: `https://github.com/bchainhub/foxar`
- Nonce-fix sequence to check first: `cba86ce` (`fix: nonce on simulation`), `d980b35` (`fix: deploy nonce`), `4f6db45` (`fix: nonce`).

Network profiles (recommended explicit config):
- Do not rely on implicit defaults; select a profile and pass explicit flags/env.
- Node endpoints are listed in `## 2) Network Endpoints`.
- Devin:
  - address prefix: `ab...`
  - rpc: `https://xcbapi.corecoin.cc/`
  - network id: `3`
- Mainnet:
  - address prefix: `cb...`
  - rpc: `https://xcbapi.coreblockchain.net/`
  - network id: `1`

Address prefix validation:
- All addresses in one run must match selected network prefix.
- Devin runs use `ab...`; mainnet runs use `cb...`.
- Prefix mismatch should be treated as configuration error first.

Known `probe send` quirk:
- In this foxar build, `probe send` may incorrectly fall back to `Private(1337)` unless `FOXAR_NETWORK_ID` is set explicitly.
- `--wallet-network mainnet|devin` alone may be insufficient for `probe send`.
- Prefer:
  - `FOXAR_NETWORK_ID=mainnet probe send ...`
  - `FOXAR_NETWORK_ID=devin probe send ...`
- `probe send --create` note:
  - Direct deployment via `probe send --create <creation-bytecode>` works on Devin when `FOXAR_NETWORK_ID`, `--rpc-url`, `--private-key`, `--energy-price`, and a sufficient `--energy-limit` are set explicitly.
  - For simple implementation-only deploys, `probe estimate --create <creation-bytecode>` returned the same energy as successful `spark create`.
- `probe compute-address` caveat:
  - In this foxar build, `probe compute-address` may unexpectedly try `http://localhost:8545` unless `--rpc-url` is passed explicitly.
  - Treat missing `--rpc-url` there as a tooling issue, not as a contract/deploy failure.

Devin faucet flow (native XCB):
- Generate Devin-compatible keypair: `probe wallet new --network devin`.
- Faucet endpoint: `POST https://api.devin.energy/api/claim` as multipart form.
- Field: `address` (Devin-prefixed, no `0x`; this rule applies to the faucet request only).
- Verify funds: `probe rpc --rpc-url https://xcbapi.corecoin.cc/ xcb_getBalance ab<address> latest`.

Spark deploy/script guidance:
- Build: `spark build`
- Create deployment:
  - `spark create src/<YourContract>.sol:<YourContract> --rpc-url <rpc> --network-id <id> --private-key "$PK"`
- Script (read-only):
  - `spark script script/<Script>.s.sol:<Script> --rpc-url <rpc> --network-id <id>`
- Script (broadcast):
  - `spark script script/<Script>.s.sol:<Script> --rpc-url <rpc> --network-id <id> --private-key "$PK" --broadcast`
- Broadcast artifact caveat:
  - `broadcast/.../run-*.json` may show an invalid placeholder `energyPrice` even when the on-chain transaction used the correct price.
  - Do not trust `broadcast` JSON for final fee diagnostics; confirm `energyPrice`, `energy`, status, and input from on-chain transaction/receipt data.
- `--skip-simulation` caveat:
  - In the current foxar build, `spark script --broadcast --skip-simulation` may break even a minimal `CREATE` deployment on Devin.
  - If `spark create` works but `spark script --broadcast` fails with `status = 0`, retry without `--skip-simulation` before investigating contract logic.
- If startup/simulation shows address-prefix errors, pin origin:
  - `--sender "0x$ADDRESS" --tx-origin "0x$ADDRESS"`

Spark test cheatcodes for signatures:
- In `spark-std/Test.sol`, use `makeAddrAndKey("label")` when tests need a matched address + private key pair.
- Use `vm.sign(privateKey, digest)` to produce the Core 171-byte signature blob for permit / EIP-712 tests.
- Use `vm.addr(privateKey)` or `vm.rememberKey(privateKey)` only when you already have the private key and need the corresponding address.
- For typed-data tests, compute the digest explicitly and then sign that digest; do not expect a separate `signTypedData` cheatcode.

Energy price policy:
- For broadcast deploy/script flows, set energy price explicitly.
- Preflight check:
  - `probe rpc --rpc-url <rpc-url> xcb_energyPrice`
- Use explicit flag:
  - `--energy-price <value>` (or `--with-energy-price <value>` where applicable)
