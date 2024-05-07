# RTB Platform Module

This Move code module, `rtb_platform::rtb_platform`, facilitates real-time bidding (RTB) functionalities within the Sui blockchain ecosystem. It enables users to create advertisements, place bids on advertisement slots, and manage user accounts. The module ensures secure and efficient handling of RTB transactions while maintaining integrity and reliability.

## Struct Definitions

### Advert

- **id**: Unique identifier for the advertisement.
- **title**: Title of the advertisement.
- **details**: Detailed description of the advertisement.
- **audienceType**: Type of audience targeted by the advertisement.
- **advertiser**: Address of the advertiser.
- **publisher**: Optional address of the publisher.
- **budget**: Budget allocated for the advertisement.
- **adSlots**: Number of advertisement slots.
- **createdAt**: Timestamp indicating the creation time of the advertisement.

#### Bid

- **id**: Unique identifier for the bid.
- **advertId**: Identifier of the advertisement being bid on.
- **amount**: Amount bid for the advertisement slot.
- **adSlots**: Number of advertisement slots bid for.
- **details**: Additional details or notes regarding the bid.
- **advertiserId**: Identifier of the advertiser placing the bid.

#### User

- **id**: Unique identifier for the user.
- **principal**: Address associated with the user.
- **userName**: Username chosen by the user.
- **email**: Email address of the user.
- **userType**: Type of user (e.g., advertiser).
- **adverts**: Vector containing identifiers of advertisements created by the user.

---

### Entry Functions

#### create_user

Creates a new user with the provided details and adds them to the system.

#### create_advert_slot

Creates a new advertisement slot with the specified parameters and associates it with the advertiser.

#### bid_ad_slots

Places a bid for advertisement slots on a specific advertisement.

#### select_bid

Selects a bid for an advertisement slot, updating the advertisement's publisher and deducting the corresponding ad slots from the available slots.

---

## Prerequisites

1. Install dependencies by running the following commands:

   - `sudo apt update`

   - `sudo apt install curl git-all cmake gcc libssl-dev pkg-config libclang-dev libpq-dev build-essential -y`

2. Install Rust and Cargo

   - `curl https://sh.rustup.rs -sSf | sh`

   - source "$HOME/.cargo/env"

3. Install Sui Binaries

   - run the command `chmod u+x sui-binaries.sh` to make the file an executable

   execute the installation file by running

   - `./sui-binaries.sh "v1.21.0" "devnet" "ubuntu-x86_64"` for Debian/Ubuntu Linux users

   - `./sui-binaries.sh "v1.21.0" "devnet" "macos-x86_64"` for Mac OS users with Intel based CPUs

   - `./sui-binaries.sh "v1.21.0" "devnet" "macos-arm64"` for Silicon based Mac

## Installation

1. Clone the repo

   ```sh
   git clone https://github.com/Edwin-KG/rtb-platform.git
   ```

2. Navigate to the working directory

   ```sh
   cd rtb-platform
   ```

## Run a local network

To run a local network with a pre-built binary (recommended way), run this command:

```sh
RUST_LOG="off,sui_node=info" sui-test-validator
```

## Configure connectivity to a local node

Once the local node is running (using `sui-test-validator`), you should the url of a local node - `http://127.0.0.1:9000` (or similar).
Also, another url in the output is the url of a local faucet - `http://127.0.0.1:9123`.

Next, we need to configure a local node. To initiate the configuration process, run this command in the terminal:

```sh
sui client active-address
```

The prompt should tell you that there is no configuration found:

```sh
Config file ["/home/codespace/.sui/sui_config/client.yaml"] doesn't exist, do you want to connect to a Sui Full node server [y/N]?
```

Type `y` and in the following prompts provide a full node url `http://127.0.0.1:9000` and a name for the config, for example, `localnet`.

On the last prompt you will be asked which key scheme to use, just pick the first one (`0` for `ed25519`).

After this, you should see the ouput with the wallet address and a mnemonic phrase to recover this wallet. You can save so later you can import this wallet into SUI Wallet.

Additionally, you can create more addresses and to do so, follow the next section - `Create addresses`.

### Create addresses

For this tutorial we need two separate addresses. To create an address run this command in the terminal:

```sh
sui client new-address ed25519
```

where:

- `ed25519` is the key scheme (other available options are: `ed25519`, `secp256k1`, `secp256r1`)

And the output should be similar to this:

``` sh
╭─────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Created new keypair and saved it to keystore.                                                   │
├────────────────┬────────────────────────────────────────────────────────────────────────────────┤
│ address        │ 0x05db1e318f1e4bc19eb3f2fa407b3ebe1e7c3cd8147665aacf2595201f731519             │
│ keyScheme      │ ed25519                                                                        │
│ recoveryPhrase │ lava perfect chef million beef mean drama guide achieve garden umbrella second │
╰────────────────┴────────────────────────────────────────────────────────────────────────────────╯
```

Use `recoveryPhrase` words to import the address to the wallet app.

### Get localnet SUI tokens

```sh
curl --location --request POST 'http://127.0.0.1:9123/gas' --header 'Content-Type: application/json' \
--data-raw '{
    "FixedAmountRequest": {
        "recipient": "<ADDRESS>"
    }
}'
```

`<ADDRESS>` - replace this by the output of this command that returns the active address:

```sh
sui client active-address
```

You can switch to another address by running this command:

```sh
sui client switch --address <ADDRESS>
```

## Build and publish a smart contract

### Build package

To build tha package, you should run this command:

```sh
sui move build
```

If the package is built successfully, the next step is to publish the package:

### Publish package

```sh
sui client publish --gas-budget 100000000 --json
` - `sui client publish --gas-budget 1000000000`
```
