# TickSys

This package contains a framework, which enables integration between SAP and ticket systems. Out of the box; it supports [Jira](http://atlassian.com) . 

## Installation

First, install dependencies.

- [Addict](https://github.com/keremkoseoglu/addict)

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

Go to SM59 and create a new "HTTP Connection to External Server" entry. This should point to your Jira system.

<table>
  <tr>
    <td><b>Target Host</b></td>
    <td>(your root Jira URL)</td>
  </tr>
  <tr>
    <td><b>Path Prefix</b></td>
    <td>/rest/api/2/search</td>
  </tr>
</table>

Add a new entry to **YTTICKSYS_JIDEF** with the following values

<table>
  <tr>
    <td><b>SYSID</b></td>
    <td>(Your SY-SYSID)</td>
  </tr>
  <tr>
    <td><b>SEARCH_RFC_DEST</b></td>
    <td>(Name of the RFC destination you created above)</td>
  </tr>
</table>

Check the menu **YTICKSYS** for any further configuration which may have been missed in this document.

## Implementing a new ticketing system

Create a new class, implementing the interface **YIF_TICKSYS_TICKETING_SYSTEM** . You may inspect **YCL_TICKSYS_JIRA** as an implementation example.

Register the new class into **YTTICKSYS_TICSY** as explained above, in Jira section.
