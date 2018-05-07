DittBox.iOS
==============================

## Introduction

DittBox is a demo application integrating ownCloud over elastos carrier network, and through which we can access or save personal files to ownCloud server that could be deployed **at home behind the router**.

## Highlights

This app demonstrates that all traditional http(/https)-based application can be refactored to elastos carrier apps running over carrier network. Being elastos carrier web app, the app server can be deployed without requirement of direct network accessibiblity.

For example, through elastos carrier network, you can deploy ownCloud server in local network at your home, and access ownCloud service at anywhere.

## Build from source

Run following commands to get full source code:

```shell
$ git clone --recurse-submodules git@github.com:elastos/Elastos.DittoBox.iOS.git
```

or

```shell
$ git clone git@github.com:elastos/Elastos.DittoBox.iOS.git
$ git submoudle update --init --recursive
```

Then open this project with Xcode to build distribution.

## Dependencies

### 1. ownCloud

See details for ownCloud in **README.ownCloud.md**.

### 2. Elastos Carrier

See details for elastos carrier in **https://github.com/elastos/Elastos.NET.Carrier.iOS.SDK**, and build **ElastosCarrier.framework** with instructions.

## Deployment

Before to run DittoBox on iOS, you need to have DittoBox server to connect with. About how to build and install ownCloud server and DittBox server, please refer to instructions in following repository:

```
https://github.com:elastos/Elastos.DittoBox.Server.git
```

## Run

After build and installation of DittBox on iOS, you need to scan QRcode of DittBox agent address to pair at first. When pairing server succeeded, then you can use ownCloud to access and save files as origin ownCloud does.

Beaware, due to carrier is decentralized network, there would be a moment about 5~30s for DittoBox app to get completely connected to carrier network and get friends connected (or online).

## Thanks

All works base on ownCloud and elastos carrier iOS SDK. Thanks to ownCloud team (especially) and carrier team.

## License

GPLv3

