# AHB-Lite Multi-Slave Bus System

This project implements an **AMBA AHB-Lite** bus system with multiple slaves. The design demonstrates basic interconnect logic, address decoding, and peripheral integration.

## Overview
The system contains:
- **Master** – Generates bus transactions.
- **Two Slaves**:
  1. **Register File** – A simple memory-mapped register bank for storing and retrieving data.
  2. **Timer Module** – Supports three modes of operation:
     - **Normal Timer** – Counts clock cycles and triggers an interrupt when reaching a programmed value.
     - **Watchdog Timer** – Resets the system if not refreshed within a certain time period.
     - **PWM Mode** – Generates a Pulse Width Modulated signal with configurable duty cycle.

## Features
- AHB-Lite protocol compliant.
- Address decoding for multiple slave selection.
- Simple, modular design for easy expansion.
- Timer mode selection via memory-mapped registers.
- Reset synchronization supported
- Fully synchronous design.

## Block Diagram
