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
    <td>(Source status ID. Sample: 10306)</td>
  </tr>
  <tr>
    <td><b>TO_STATUS</b></td>
    <td>(Target status ID. Sample: 10313)</td>
  </tr>
  <tr>
    <td><b>TRANSITION_ID</b></td>
    <td>(Transition ID. Sample: 91)</td>
  </tr>
</table>

Add new entries to **YTTICKSYS_JISTA** . This table determines the assignee to be assigned to the issue after a status update.

<table>
  <tr>
    <td><b>STATUS_ID</b></td>
    <td>(Source status ID, leave blank for default. Sample: 10306)</td>
  </tr>
  <tr>
    <td><b>JIRA_FIELD</b></td>
    <td>(Field name containing the assignee. Sample: customfield_10114)</td>
  </tr>
  <tr>
    <td><b>PRIORITY</b></td>
    <td>(Priority of this rule)</td>
  </tr>
</table>

If you have custom fields for request transportation instructions, you need to register their custom fields into **YTTICKSYS_JITIF** .

<table>
  <tr>
    <td><b>JIRA_FIELD</b></td>
    <td>(Field name containing instructions. Sample: customfield_10427)</td>
  </tr>
</table>

If you have custom fields containing related SAP TCode values, you need to register their custom fields into **YTTICKSYS_JITCF** . It is assumed that this custom field can contain multiple values.

<table>
  <tr>
    <td><b>JIRA_FIELD</b></td>
    <td>(Field name containing instructions. Sample: customfield_10006)</td>
  </tr>
</table>

If you have custom fields containing main SAP module, you need to register their custom fields into **YTTICKSYS_JIMMF** . The program will find the first non-empty field and assume it to be the main module.

<table>
  <tr>
    <td><b>JIRA_FIELD</b></td>
    <td>(Field name containing instructions. Sample: customfield_10109)</td>
  </tr>
</table>

If you will be using **GET_EARLIEST_STATUS**, you need to fill **YTTICKSYS_JISTO** with the correct order of Jira statuses. This table is text based because ID's may change with each new definition, but status descriptions are typically stable.

<table>
  <tr>
    <td><b>JSTATUS_TEXT_PATTERN</b></td>
    <td>(Status text pattern. Sample: DUZELTILIYOR*)</td>
  </tr>
  <tr>
    <td><b>STATUS_ORDER</b></td>
    <td>(Order of status. Sample: 9)</td>
  </tr>
</table>

Check the menu **YTICKSYS** for any further configuration which may have been missed in this document.

## Implementing a new ticketing system

Create a new class, implementing the interface **YIF_ADDICT_TICKETING_SYSTEM** . Details of this interface is described in [Addict](https://github.com/keremkoseoglu/addict) . You may inspect **YCL_TICKSYS_JIRA** as an implementation example.

Register the new class into **YTTICKSYS_TICSY** as explained above, in Jira section.
