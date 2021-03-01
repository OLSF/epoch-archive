# Quick Start

```
# Build the binaries, assumes your libra source at ~/libra. See ENV vars below for setting custom path

make bins

# Restore from an epoch in this archive. WILL DESTROY LOCAL DB!

EPOCH=77 make restore-all

# Create backup from a remote node (which has backup-service enabled publicly, and epoch must be within the prune window)

EPOCH=80 URL=http://167.172.248.37 make backup-all

# Update the waypoint to latest waypoint in key_store.json

```

# Archive

This repo keeps archives of 0L database at different block heights. The objective is to archive the state of heights at 1) the end of a calendar month 2) at the time of network updades.

The archive is predominantly used for new nodes to join consensus at an advanced waypoint. These backups will also allow for network recovery in catastrophic failure.

# Objective

A prospective node (full or validator) ordinarily needs to sync from the genesis transaction. This is costly and time consuming. A fast sync would start from a known waypoint.
 
A Node's libra DB needs to be "bootstrapped" at the time of the node starting. This is ordinarily done with a genesis.blob if starting from the beginning of the ledger. If catching up from an advanced waypoint, the DB needs to be bootstrapped some other way.

Backups are a way of bootstrapping the DB. There are 3 types of point-in-time backups:
- Epoch Ending
- Transactions
- State Snapshot

# Backup-cli

The goal of backups is to take the full state of a DB from a fullnode or validator, to accelerate the sync of a new prospective node.
To do this a waypoint and version (blockheight) will be needed.

## Makefile

Many of the typical operations of the backup tools (db-restore, db-backup) can be automated with the sample Makefile.

# Env Variables

EPOCH:  this variable must be set by user before calling makefile.

`EPOCH=30 make restore-all`

SOURCE_PATH: optional, the path of libra source, for building bins. Will default to `~/libra`

ARCHIVE_PATH: optional, the path of this repo. Will default to `~/epoch-archive`

DB_PATH: optional for backups only, path to the node's database. Will default  to `~/.0L/db`

URL: optional for backups only, url of backup service. Will default to `http://localhost`. Can use a remote node which has the backup-service-address open to `0.0.0.0/6186`
