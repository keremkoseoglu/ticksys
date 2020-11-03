# TickSys

This package contains a framework, which enables integration between SAP and ticket systems. Out of the box; it supports [Jira](http://atlassian.com) . 

## Installation

First, install dependencies.

- [Addict](https://github.com/keremkoseoglu/addict)
- [Simbal](https://github.com/keremkoseoglu/simbal)

Then, install TickSys using [abapGit](https://github.com/abapGit/abapGit) .

## Configuration

The configuration is available under the menu **YTICKSYS** .

## Activating Jira

Add a new entry to **YTTICKSYS_TICSY** with the following values:

<table>
  <tr>
    <td><b>TICSY_ID</b></td>
    <td>JIRA</td>
  </tr>
  <tr>
    <td><b>TICSY_TXT</b></td>
    <td>Jira</td>
  </tr>
  <tr>
    <td><b>TICSY_IMP_CLASS</b></td>
    <td>YCL_TICKSYS_JIRA</td>
  </tr>
</table>

Add a new entry to **YTTICKSYS_JIDEF** with the following values:

<table>
  <tr>
    <td><b>SYSID</b></td>
    <td>(Your SY-SYSID)</td>
  </tr>
  <tr>
    <td><b>URL</b></td>
    <td>(Your base Jira URL)</td>
  </tr>
  <tr>
    <td><b>USERNAME</b></td>
    <td>(Your Jira username)</td>
  </tr>
  <tr>
    <td><b>PASSWORD</b></td>
    <td>(Your Jira password)</td>
  </tr>
</table>

Add new entries to **YTTICKSYS_JITRA** for each status transition. For each "STATUS A -> STATUS B" transition, Jira has a unique transition ID. This table stores those values. In You may need help from your Jira admin to get those ID's since they are not visible on the user interface.

<table>
  <tr>
    <td><b>FROM_STATUS</b></td>
    <td>(Source status ID)</td>
  </tr>
  <tr>
    <td><b>TO_STATUS</b></td>
    <td>(Target status ID)</td>
  </tr>
  <tr>
    <td><b>TRANSITION_ID</b></td>
    <td>(Transition ID)</td>
  </tr>
</table>

Check the menu **YTICKSYS** for any further configuration which may have been missed in this document.

## Implementing a new ticketing system

Create a new class, implementing the interface **YIF_ADDICT_TICKETING_SYSTEM** . Details of this interface is described in [Addict](https://github.com/keremkoseoglu/addict) . You may inspect **YCL_TICKSYS_JIRA** as an implementation example.

Register the new class into **YTTICKSYS_TICSY** as explained above, in Jira section.
