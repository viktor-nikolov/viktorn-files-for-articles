# Trenz 7020-2I SoC module FreeRTOS lwIP iperf client (Vitis 2025.1)

The file [archive_Trenz7020-2I_RTOS_iperf_client.zip](archive_Trenz7020-2I_RTOS_iperf_client.zip) is a project export from Vitis 2025.1, which contains a FreeRTOS lwIP iperf client built for the Trenz AMD Zynq SoC module 7020-2I.  
I tested it with my [TE0720-04-62I33MA](https://www.trenz-electronic.de/en/SoC-Module-with-AMD-Zynq-7020-2I-1-GByte-DDR3L-8-GByte-eMMC-4-x-5-cm/TE0720-04-62I33MA) with the carrier board [TE0705](https://www.trenz-electronic.de/en/TE0705-Simplified-carrier-board-based-upon-TE0701/TE0705-04). I achieved an average transfer speed of 566 Mbits/sec.

> [!NOTE]
>
> Please note that I created this Vitis 2025.1 project export on Windows, and it is, unfortunately, not usable on Linux. This is because Vitis stores names of build executables in the BSP configuration. Linux executables differ from those on Windows. Generally, Vitis exports are not compatible across different operating systems.

This version of FreeRTOS iperf client is improved, because I fixed a performance bug present in the original AMD example.  
In the original code, `xemacif_input_thread` is set to run with the default thread priority. Therefore, there is a bottleneck in the handling of incoming packets. The priority must be set to `TCPIP_THREAD_PRIO`, which is the priority of the main lwIP `tcpip_thread` (see tcpip.c in the lwIP BSP source files).

In main.c of the FreeRTOS lwIP TCP Perf Client, a change in the code in the function `network_thread` is needed as follows:

```c
/* start packet receive thread - required for lwIP operation */
sys_thread_new("xemacif_input_thread",
        (void(*)(void*))xemacif_input_thread, &server_netif,
        THREAD_STACKSIZE,
//      DEFAULT_THREAD_PRIO); // Original setting. Too low priority.
        TCPIP_THREAD_PRIO);
```

This fix increases the lwIP iperf client performance by 11%.