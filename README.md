# Assets for starcoin networks

## Automated refresh

The workflow defined in `.github/workflows/daily-network-update.yml` rebuilds the Move stdlib artefacts and pre-generated genesis blobs every day at 01:00 Beijing time (17:00 UTC). It performs the following steps:
- clones the `starcoin` workspace, points its `networks` folder at this repository, and runs the official generators to refresh `stdlib/` and `genesis/`;
- commits any changes to the `latest` branch of `starcoinorg/starcoin-networks`;
- updates the `networks` submodule in `starcoinorg/starcoin` and opens an automation PR targeting the `dual-verse-dag` branch.

To let the second phase push to `starcoinorg/starcoin`, add a Personal Access Token (classic PAT with `repo` scope) named `STARCOIN_AUTOMATION_PAT` to this repository’s secrets. This token must have write access to the `dual-verse-dag` branch in `starcoinorg/starcoin`. Optional environment overrides for the regeneration script are documented in `scripts/update_network_assets.sh`.
