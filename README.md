# AHB-Lite Multi-Slave Bus System

This project implements an **AMBA AHB-Lite** bus system with multiple slaves. It demonstrates **multi-master support**, **address decoding**, **AHB-to-APB bridging**, and **peripheral integration**.

---

## **Features**

* **AHB-Lite Protocol Compliant**
* **Multi-Master Arbitration** – Supports multiple bus masters with arbitration logic.
* **AHB-to-APB Bridge** – Provides access to APB-based peripherals.
* **Generic AHB & APB Slave Support**
* **Address Decoding** for multiple slave selection.
* **Timer Module** with:

  * Normal Timer Mode (interrupt on match)
  * Watchdog Timer Mode (system reset on timeout)
  * PWM Mode (configurable duty cycle)
* **Memory-Mapped Register File**
* **Reset Synchronization**
* **Fully Synchronous Design**
* **Modular and Scalable Architecture**

---

## **System Overview**

The system includes:

* **Masters** – Multiple initiators capable of generating bus transactions.
* **Slaves**:

  1. **Register File** – Simple memory-mapped register bank.
  2. **Timer Module** – Configurable timer with three modes.
  3. **Other Peripherals** – Accessible via AHB-to-APB bridge.
* **AHB-to-APB Bridge** – Converts AHB transactions to APB protocol for peripheral access.

---

## **Multi-Master Support**

* Arbitration ensures only one master accesses the bus at a time.
* Supports extension for additional masters.
* Can integrate fixed-priority or round-robin arbitration schemes.


## **Block Diagram**

*(Insert your diagram here – showing Masters, AHB Bus, Slaves, AHB-to-APB Bridge, Arbitration)*

---

## **License**

This project is licensed under the MIT License – see [LICENSE](LICENSE) for details.

