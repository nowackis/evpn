# 🌐 Networking Engineering Training: EVPN Labs

Welcome to the EVPN lab collection.

This directory contains hands-on labs that demonstrate how EVPN fabrics work using
Linux Network Namespaces, Docker, and FRRouting (FRR).

The goal is to make EVPN *observable*, *debuggable*, and *understandable* by exposing
both control-plane and kernel data-plane behavior.

---

## 🧠 Mental Model

Before deploying any lab, it is essential to understand the kernel primitives used
to build the fabric.

### Core Concepts

- **Network Namespace**
  - An isolated copy of the Linux networking stack
  - Includes interfaces, routing tables, ARP/ND, netfilter, and sockets
  - Think of it as a *mini-kernel networking universe*

- **Routing Table**
  - A collection of routes inside a namespace
  - A single namespace can have multiple tables (main, local, VRF tables)

- **Route**
  - A rule the kernel uses to forward packets
  - Defined by destination prefix, output interface, and optional next-hop

- **Veth Pair**
  - A virtual Ethernet cable
  - Used to connect namespaces together

---

## 🏗️ Topology Overview

All EVPN labs follow a Spine–Leaf CLOS architecture:

- **Spines**
  - Run the underlay only
  - Provide IP reachability between VTEPs

- **Leafs**
  - Run underlay + overlay
  - Act as VTEPs
  - Perform EVPN L2/L3 services (Symmetric IRB)

- **Hosts**
  - Dedicated namespaces
  - Connected to leaf bridges
  - Represent tenant workloads

---

## 📁 Lab Structure

Each lab directory is self-contained and includes:
- Device configuration files
- Startup and cleanup scripts
- Diagrams
- Optional implementation documentation
- An `install.md` file with step-by-step instructions to deploy and run the lab

### Available Labs

- `EVPN-eBGP-unnumbered/`
  - EVPN over eBGP unnumbered underlay
- `EVPN-iBGP/`
  - EVPN over iBGP underlay
- `EVPN-iBGP-unnumbered/`
  - EVPN over iBGP unnumbered

---

## 🎥 Video Walkthroughs

Hands-on video walkthroughs that explain both the *why* and the *how* of the labs.

- **EVPN over eBGP (Unnumbered Underlay)**
  - 🎬 [Video walkthrough](videos/evpn-ebgp-unnumbered.mp4)
  - Covers:
    - Underlay bring-up
    - EVPN control-plane (Type 2 / Type 5)
    - Kernel dataplane inspection
    - Debugging techniques

More videos will be added as labs evolve.

---

## 📖 Documentation

Each lab directory may include:
- A `README.md` for usage instructions
- An implementation document for deep technical details
- Diagrams (`.drawio`, `.png`)
- Recordings or walkthroughs (when available)

If you want to *understand why something works*, read the implementation doc.  
If you just want to *run the lab*, start with the lab README.