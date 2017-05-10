# Liflaf

![Liflaf](http://www.asterix.com/asterix-de-a-a-z/les-personnages/perso/a16b.gif)

The Normans where the champions of shipping stuff around in the old days. Liflaf
(in the Dutch edition) is the fearless head of a band of Normans.

Liflaf ships data around. I have stuff on Linux (so I can't use Dropbox), I'm
not superhappy with the complexity of [Git Annex](https://git-annex.branchable.com/),
and I thought that it should be relatively simple in Elixir to build a
synchronization daemon.

This is a longer-term project I work on when I want to.

# RDD (Readme Driven Development)

## Assumptions

* This is meant to sync my laptops and my RPi3 fileserver for files I want on all machines, like dotfiles and other config stuff, notes in org-mode, etcetera.
* Nodes fully trust each other. This is a feature.
* It runs on a LAN so can be chatty. This is also a feature.
* Last writer wins based on host clocks. Run NTP.
* The use case is that I work on one laptop, it gets synced to my RPi3, I then move to a next laptop and it automatically refreshes from the RPi3. Or laptop-to-laptop when both are open.
* Data is kept so that `rsync -avz` can be used to catch up large changes.

## Basic networking

* [x] `~/.liflaf/id` is a one-time created unique id for the node.
* [x] `~/.liflaf/peers` is a file with a list of Erlang node names that are peers.
* [x] A Node has `~/LifLaf/` as the shared folder (all paths from here are relative)
* [x] A Node reads its id on startup, and globally registers itself under that name.
* [x] A Node reads its peers file on startup and attempts to connect with all of them.

## Basic initial synchronization

* [x] A Node constructs a Merkle tree by having a ~/.dir_hash xxHash in every directory.
* [x] ~/.dir_hash contains hashes for the directory (including its children) and each file.
* [ ] Every second, a node sends the hash of its root directory to its peers.
* [ ] If there is a hash mismatch, the receiving node sends the hashes of the next directory level back as [{dirname, hash}] tuples.
* [ ] When two nodes figure out which directory changed, they exchange a filelist as [{filename, hash, timestamp}] tuples.
* [ ] The node with the older timestamp for a file requests the newer file from the other node.

## Basic ongoing synchronization

* [ ] A Node creates a filesystem watch on the root directory.
* [ ] Changes in `.node` are ignored.
* [ ] Any other changes result in the update of the Merkle tree hashes back to the root.

## Security

It runs on my LAN. Security is optional. So this might never get done :-)

* [ ] A Node uses a secure protocol to talk to other nodes, based on SSH. See for example [this talk](http://www.erlang-factory.com/upload/presentations/214/ErlangFactorySFBay2010-KenjiRikitake.pdf) and [the base docs](http://erlang.org/doc/apps/erts/alt_dist.html).
* [ ] Nodes need a pre-shared key, stored in `~/.liflaf/psk` to be able to talk to other nodes with the same PSK.
* [ ] Optionally, the PSK is found in `~/.liflaf/psk.enc` which will make the node ask for a password to decrypt the PSK. This is the most secure mode.

## Cool stuff

May be done before security is done.

* [ ] A "special node" pushes data, encrypted, to S3/B2/...
