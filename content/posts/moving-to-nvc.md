---
title: "Open-Source VHDL Simulation: Moving from GHDL to NVC"
date: 2025-06-27T15:48:07-04:00
draft: false
author: Jimmy Vogel
description: We recently switched from using GHDL to using NVC as our open-source VHDL simulator of choice. This post discusses why we decided to make the change, the work it required, and how it all turned out.
---

We recently switched from using [GHDL](https://github.com/ghdl/ghdl) to using [NVC](https://github.com/nickg/nvc) as our open-source VHDL simulator of choice. This post discusses why we decided to make the change, the work it required, and how it all turned out.

## Motivation: VHDL-2019

Here at MicroNova, we do a lot of FPGA work. It's certainly not all we do (see: [AmpliPi](https://github.com/micro-nova/AmpliPi)/[AmpliPro](https://www.amplipro.com/)), but it's our [~~bread and butter~~](https://en.wikipedia.org/wiki/Bread_and_Butter_(playboating)) [bread and butter](https://en.wiktionary.org/wiki/bread_and_butter).

We mainly write our FPGA projects in VHDL and target Xilinx hardware. We've been making use of VHDL-2008 features for a while now, since [Vivado supports many of the useful features in this standard](https://docs.amd.com/r/en-US/ug901-vivado-synthesis/Supported-VHDL-2008-Features). However, one thing that we've been missing since the VHDL-2019 standard was published is [interfaces](https://docs.amd.com/r/en-US/ug901-vivado-synthesis/Interfaces?tocId=YiYQDeCmIQLcxnwy_wZVBg).

The cool thing about interfaces is that they let you simplify verbose bus port interfaces down to a single line, which can really help to clean up code.

Say you have an AXI bus in your design. Without interfaces, you would have all of these signals passing through each component in the hierarchy down to the lowest level with AXI logic:

```vhdl
entity axi_master is
  port (
    clk           : in  std_logic;
    m_axi_awvalid : out std_logic;
    m_axi_awready : in  std_logic;
    m_axi_awaddr  : out std_logic_vector(48 downto 0);
    m_axi_awsize  : out std_logic_vector(2 downto 0);
    m_axi_awburst : out std_logic_vector(1 downto 0);
    m_axi_awid    : out std_logic_vector(5 downto 0);
    m_axi_awlen   : out std_logic_vector(7 downto 0);
    m_axi_wvalid  : out std_logic;
    m_axi_wready  : in  std_logic;
    m_axi_wlast   : out std_logic;
    m_axi_wdata   : out std_logic_vector(127 downto 0);
    m_axi_wstrb   : out std_logic_vector(15 downto 0);
    m_axi_bvalid  : in  std_logic;
    m_axi_bready  : out std_logic;
    m_axi_bresp   : in  std_logic_vector(1 downto 0);
    m_axi_bid     : out std_logic_vector(5 downto 0)
  );
end entity;
```

With VHDL-2019, you can create an interface out of this by first creating a `record` type:

```vhdl
type axi_t is record
    awvalid : std_logic;
    awready : std_logic;
    ...
end record;
```

And then you can create two `view` definitions (`view` is a new keyword), one for each direction of the bus:

```vhdl
view axi_m2s_v of axi_t is
    awvalid : out;
    awready : in;
    ...
end view;

view axi_s2m_v of axi_t is
    awvalid : in;
    awready : out;
    ...
end view;
```

And then your port list becomes:

```vhdl
entity axi_master is
  port (
    clk     : in   std_logic;
    axi_m2s : view axi_m2s_v
  );
end entity;

entity axi_slave is
  port (
    clk     : in   std_logic;
    axi_s2m : view axi_s2m_v
  );
end entity;
```

So this is great. You can put the more verbose record and view definitions in a package and and then use the concise view reference in all of your ports. Then, if anything changes in the interface, you only need to go to one place (the package definitions) to update it.

Another nice new feature in VHDL-2019 that Vivado supports is that integer types are now 64-bit instead of 32-bit, meaning you can actually represent a 32-bit memory address with an integer rather than having to use `unsigned(31 downto 0)` and do a type conversion whenever you want to use it as an index. We are big on using the right datatype for the task and keeping our code clean, so this helps.

## Roadblock: Simulator Support

We're big fans of open-source software. It tends to be more modular and easier to install and run everywhere (development machines, cloud CI/CD runners, build servers) compared to the vendor tools with huge install sizes and license to contend with. So for our FPGA workflow we prefer to use as many open-source tools as possible.

For a while now, our go-to VHDL simulator has been [GHDL](https://github.com/ghdl/ghdl). However, GHDL only officially supports up to VHDL-2008. So when we started talking about moving to VHDL-2019, we realized we would need to find another simulator.

Luckily, in the vast world of open-source software, there's another fantastic VHDL simulator called [NVC](https://github.com/nickg/nvc), and it has [great VHDL-2019 support](https://www.nickg.me.uk/nvc/features.html)!

After migrating to NVC, we found that our tests ran in less than half the time, and they didn't freeze our machines when we accidentally ran too many tests in parallel that allocated large buffers (more on that later), so that was a nice bonus on top of supporting the new language features.

## Making the Switch

We had hoped that switching from GHDL to NVC would be as simple as just changing a parameter in our test script, but it ended up being a little bit more involved.

### Setting up VUnit

We use another open-source tool, [VUnit](https://github.com/VUnit/vunit), as our test framework, and we use it for running all of our simulations. So the first thing to do was investigate how VUnit would work with NVC compared to GHDL.

The interface to VUnit is a Python script called `run.py`. The main part of the script looks something like this:

```python
from vunit import VUnit

# Create a VUnit project instance from command line arguments
vu = VUnit.from_argv()

# Add VUnit's built-in utilities for checking, logging, communication...
vu.add_vhdl_builtins()
...
# Add source files and configure tests
...
# Run tests
vu.main()
```

When you run this script, it looks for any supported simulator in your path to compile and run the specified testbench code. We found that GHDL had a higher priority in this search, so we needed to set an environment variable to override the simulator choice to avoid using the wrong simulator on a machine with both NVC and GHDL installed. Luckily, you can do this from within Python:

```python
from os import environ

# Set VUnit simulator to NVC via env var (needed if GHDL is also installed)
environ["VUNIT_SIMULATOR"] = "nvc"
```

We also needed to tell VUnit to use the VHDL-2019 standard, since that was the whole point of this exercise:

```python
vu = VUnit.from_argv(vhdl_standard="2019")
```

With those minor tweaks, we were able to get our tests running with NVC. However, there were a few more things to clean up.

One thing we discovered is that by switching to the new standard, we could remove the following lines from our script, as it turned out they were basically just [polyfills](https://en.wikipedia.org/wiki/Polyfill_(programming)) for VHDL-2008:

```python
# Add error context to VUnit's "check_relation" messages
vu.enable_check_preprocessing()

# Add file name and line number to VUnit's "check" and "log" messages
vu.enable_location_preprocessing()
```

These features are essential for tracking down the source of error messages in complex projects, but VUnit's preprocessing step causes all file paths printed in simulator messages to point to files in the `vunit_out` directory rather than the original source file path, which caused problems with our language server ([VHDL-LS](https://github.com/VHDL-LS/rust_hdl) via [TerosHDL](https://github.com/TerosTechnology/vscode-terosHDL)) and click-to-open from the VS Code terminal, so being able to get rid of preprocessing was a welcome surprise!

The next thing we noticed is that we had a few simulator-specific configurations that we were telling VUnit to pass to GHDL to set things like relaxed elaboration for Xilinx [UNISIM](https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation/UNISIM-Library) library files. Those could be removed as they didn't apply to NVC, but they might need to be replaced with equivalents.

### NVC issues

Speaking of UNISIM, once we got VUnit to start compiling our code with NVC in VHDL-2019 standard mode, we ran into some errors compiling the UNISIM library. NVC does have an option to copy the UNISIM files from your Xilinx installation directory into its application directory and pre-compile them for use in simulations so they don't need to be included with your project source, but these files were not written for VHDL-2019 so they would not actually compile under this standard mode. (The issue doesn't occur in VHDL-2008 mode.)

However, we already had the UNISIM sources copied into our project that we've been testing this setup with, so it was just a matter of making some minor tweaks to the code and then everything compiled. For example, `unisim_VPKG.vhd` was using `ieee.vital_timing.all` and `ieee.vital_primitives.all`, which are not included when compiling with NVC in VHDL-2019 mode, but it was straightforward to simply delete all references to those as they were not used outside of that file. Another file was using `ieee.std_logic_arith.all`, which also appeared not to be included in this scenario, so a couple function calls needed to be rewritten to use `ieee.numeric_std.all`.

After making sure all of our VHDL would compile, we ran our tests suite consisting of 39 tests, which were all previously passing with GHDL. Weirdly, now only 15 tests were passing. Looking at the logs from the tests, it appeared that the simulator process was crashing during the failing tests after running for under a second (though the nice thing about using a test runner like VUnit is that the other tests are still run, as the runner spawns a new simulator instance for each test). On a hunch, we installed the previous minor release of NVC, and guess what? No more failing tests!

To track down the issue, we followed this process:

1. Clone the NVC repo.
2. Follow the steps in the README to build and install the executable from source, but before running the build, run the `configure` script generated by [GNU Autoconf](https://www.gnu.org/software/autoconf/) with the argument `--enable-debug` so that NVC will print stack traces for crashes.
3. Run the VUnit tests and review the stack traces.
4. Add some print statements to the source before where the error is produced to narrow down which VHDL code was causing the issue.
5. Comment out lines of VHDL code until the error stops.
6. Create a minimal reproduction example that produces the same crash.
7. For extra credit, run `git bisect` to find the commit that introduced the issue.
8. Post an issue on the GitHub repo with the stack trace and the repro example.

This is the awesome thing about using open-source tools! You can inspect the code and contribute directly to developing and improving them.

What's even more awesome is that [nickg](https://github.com/nickg) committed a fix less than two hours after we posted this issue! Now that's the kind of responsiveness you want to see in a project. Plus, NVC typically has a minor release every few months (unlike GHDL, which has been on 4.7.0 for two years or so), so we should see a tagged release within the next month or so.

Oh, we also had to add the following line to our VUnit run script to make sure all of our memory arrays got dumped to waveforms for debugging:

```python
vu.set_sim_option("nvc.sim_flags", ["--dump-arrays"])
```

## Other Motivation: Memory Usage and Crashes

We mentioned earlier that we switched to NVC to get VHDL-2019 support, but actually there was a another reason that pushed us over the edge. As alluded to before, we had encountered some major freezes using GHDL, and we were hoping that NVC would resolve this.

The issue started when we defined some large memories in our project. Or maybe it was when we added the large AXI memory model from VUnit to one of our testbenches. At any rate, we typically run multiple tests in parallel with `run.py --num-threads 8` so the tests finish faster. But now doing this would completely freeze our machines, forcing us to hard reboot. We determined that this seemed to be correllated with 100% memory usage. So even though only a couple of our tests produced this issue, if we wanted to run all tests at once we could only do something like `run.py -num-threads 2`.

Incidentally, we had been using GtkWave as our waveform viewer for debugging during development. This also consumed a massive amount of RAM when trying to load the waveforms from our testbench with the large memory model, albeit without actually freezing our computers beyond recovery. So, we also ended up switching to [Surfer](https://gitlab.com/surfer-project/surfer) for our waveform viewer, which is "blazingly fast" (Rust strikes again), and has a lot of other nice features.

Anyway, freezing your computer to death when trying to run a few tests in parallel is a really annoying failure mode. So once we had NVC up and running, we checked how the problematic testbench was performing and were pleasantly surprised.

NVC would actually produce an error message on the tests with high memory usage:

```text
** Fatal: 0ms+10: out of memory attempting to allocate 402679032 byte object
   Note: the current heap size is 67108864 bytes which you can increase with the -H option, for example -H 128m
```

It even helpfully explains how to mitigate the error! Amazing.

All we had to do was add this line to our VUnit run script and the errors were gone:

```python
vu.set_sim_option("nvc.global_flags", ["-H", "1024m"])
```

(Repeated testing with incrementally increasing the size led to this value.)

Once we increased the heap size, we could do `run.py --num-threads 8` with no problem whatsoever. Sure, we peaked with 87% of 32 GB of RAM usage, but no freezes!

## Results

So, we're very happy with the results of this move. In addition to not having to worry about our computers randomly freezing, and being able to use the latest VHDL-2019 language features (at least to the extent supported by Vivado), we discovered some other benefits:

- No more preprocessing needed for VUnit checks and location, giving us clean source file paths.
- More traceable warnings from standard libraries: NVC actually prints which line in which of your source files triggered a warning, rather than just the file that produced it (unlike GHDL).

Check back later for another post outlining our complete open-source VHDL development stack (including NVC, Surfer, and uv for Python tool management)!