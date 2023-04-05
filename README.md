
# ![Logo](/media/logo.png) &nbsp; PEG SYS Components

## Introduction

The **PEG_SYS** package aims primarily at generating various Org monitoring data to be used either locally
(via standard reports and dashboards) or aggregation within **CRM Analytics** (e.g. in case of multi-Org
connections). Via a set of schedulable Apex tools, it enables to take periodic snapshots of
* **Org limits** via the standard **[OrgLimit](https://developer.salesforce.com/docs/atlas.en-us.238.0.apexref.meta/apexref/apex_class_System_OrgLimit.htm)** Apex class
* **Org Storage** via the standard **Storage Usage** Setup page (accessible from the **System Overview** setup page)

It stores snapshot data in custom object records (`CreationDate` corresponding to the snapshot timestamp) and
automatically purges old ones based on a configurable duration.

It also addresses issues specific to **CRM Analytics** (or even **Marketing Cloud**), such as:
* **Picklist Values** extraction for code-to-label picklist value mapping in DataFlows/Recipes (only the current
  situation of the configured picklist fields being stored, i.e. no history)

## List View Examples

###  **Org limits**

![Org Limit Example](/media/OrgLimit.png)

### **Org Storage**

![Org Limit Example](/media/OrgStorage.png)

### **Picklist Values**

![Picklist Example](/media/Picklist.png)


## Package Content

The package contains the following main components:
* 3 Schedulable Apex classes
    * **SYS_OrgLimitSnapshot_SCH** to schedule and execute Org limit snapshots
    * **SYS_OrgStorageSnapshot_SCH** to schedule and execute Org Storage snapshots
    * **SYS_PicklistSnapshot_SCH** to schedule and execute Picklist Values snapshots
* 3 Custom Objects
    * **SYS_OrgLimitSnapshot__c** to store Org limit snapshot data
    * **SYS_OrgStorageSnapshot__c** to store Org Storage snapshot data
    * **SYS_PicklistSnapshot__c** to store Picklist Value snapshot data
* 2 Custom Settings
    * **SYS_OrgLimitConfig__c** to configure Org limit snapshot process
    * **SYS_OrgStorageConfig__c** to configure Org Storage snapshot process
* 1 Custom Metadata
    * **SYS_PicklistLabel__mdt** to configure Picklist Field snapshot process
* 1 PermissionSet
    * **SYS_UseScheduleTools** to get all access rights necessary to run the schedulable
    Apex classes and access the snapshot data and configuration.

It also includes test elements for deployment:
* 3 Apex test classes
    * **SYS_OrgLimitSnapshot_SCH_TST** to test the SYS_OrgLimitSnapshot_SCH class
    * **SYS_OrgStorageSnapshot_SCH_TST** to test the SYS_OrgStorageSnapshot_SCH class
    * **SYS_PicklistSnapshot_SCH_TST** to test the SYS_PicklistSnapshot_SCH class
* 1 Static Resources
    * **SYS_OrgStorageSnapshot_TST** to be used as **Storage Usage** Setup page test content


## Installation

To retrieve the SFDX project, you may simply execute a git clone from the GitHub repository.
```
git clone git@github.com:pegros/PEG_SYS.git
```

Via SFDX you may then deploy it on you Org
```
sfdx force:source:deploy -u <yourOrgAlias> -w 10 --verbose -p force-app
```


## Configuration

Process configuration rely on custom setting or custom metadata records depending on the
schedulable tool.
* **Custom Setting** records are available for the Org Limits and Storage snapshots and basically
enable to set a data retention period (in days, everything being kept by default) and, for Org Limits,
to bypass some uninteresting limits (as a comma separated list of limit names).
* **Custom Metadata** records are available for the Picklist snapshot to define the set of
picklist fields to consider (the label of which should be in the `ObjectApiName.FieldApiName` format)


## Scheduling

Snapshots may be **scheduled** independently via the standard `Schedule Apex` button displayed
in the **Apex Classes** Setup page.
* The **SYS_OrgStorageSnapshot_SCH_TST** is usually scheduled once a week to really 
track visible evolution
* The **SYS_PicklistSnapshot_SCH** is usually scheduled once a day to track any evolution to 
the corresponding metadata (but it may be also be launched only manually after each new application
deployment)
* The **SYS_OrgLimitSnapshot_SCH_TST** may be scheduled multiple times per day to get finer view 
of the limit evolution (for now, there is a single schedule for all limits).

⚠️ **Beware** that the **SYS_PicklistSnapshot_SCH** schedulable will systematically fail
if bad Picklist names are registered in the `MasterLabel`of any **SYS_PicklistLabel__mdt** metadata
record in `active` status. It may thus be useful to check the configuration validity after any
modification by launching the following command from the developer console:
```
SYS_PicklistSnapshot_SCH.execute(null);
```


## CRM Analytics Aggregation

Snapshot data may be easily aggregated in a **CRM Analytics** instance from multiple Salesforce Org by
* fetching the custom object records via `sfdcDigest` or `digest` nodes
* compute additional Org name and record Unique ID fields via `compute` nodes
* aggregate the records in a single dataset via an `append` node
* register it via a final `register` node

![Data Aggregation DataFlow](/media/DataAggregation.png)

Such a DataFlow (may also be done in a Recipe) may be extended to manage longer term historisation in
**CRM Analytics** (e.g. by keeping only 10 day sliding window in the Salesforce Orgs).

## Installation
<a href="https://githubsfdeploy.herokuapp.com?ref=master">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>
