
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

A **CRM Analytics** application is also provided to monitor the snapshots.

## List View Examples

By default, snapshot data may be easily managed directly on Salesforce core 
vi simple list views and standard reports.

###  **Org limits**

![Org Limit List View](/media/OrgLimit.png)

### **Org Storage**

![Org Limit List View](/media/OrgStorage.png)

### **Picklist Values**

![Picklist List View](/media/Picklist.png)


## CRM Analytics Dashboard Examples

When **CRM Analytics** is available, some dashboards are available.

###  **Org limits**

![Org Limit Analytics Dashboard](/media/OrgLimitsMonitoring.png)

### **Org Storage**

![Org Limit Analytics Dashboard](/media/OrgStorageMonitoring.png)



## Package Content

The package is split into two folders respectively containing
* the main Apex package (`default` folder)
* a sample CRM Analytics monitoring App (`wave` folder)

### Main Package (`default` folder)

The main package contains the following main components:
* 3 Schedulable Apex classes
    * **SYS_OrgLimitSnapshot_SCH** to schedule and execute Org limit snapshots
    * **SYS_OrgStorageSnapshot_SCH** to schedule and execute Org Storage snapshots
    * **SYS_PicklistSnapshot_SCH** to schedule and execute Picklist Values snapshots
* 3 Custom Objects (+ 3 associated tabs)
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


### CRM Analytics Package (`wave` folder)

The CRM Analytics package contains the following components:
* a CRM Analytics App (**SYS Monitoring**)
* 2 dashboards (**SYS Org Limits Monitoring** and **SYS Org Storage Monitoring**)
* 2 datasets (**SYS OrgLimits** and **SYS OrgStorage**)
* 2 recipes (+ 2 related dataflows required for metadata deployment), respectively for
    * dataset initialisation (**SYS Monitoring Init**), typically used once to inject the initial dataset data
    * periodic dataset update (**SYS Monitoring**), typically to be scheduled to append new synched data in the existing datasets
* 1 content asset (i.e. the logo embedded in the dashboards)

## Installation

### Git Deployment

To retrieve the SFDX project, you may simply execute a git clone from the GitHub repository.
```
git clone git@github.com:pegros/PEG_SYS.git
```

Via SFDX you may then deploy it on you Org
```
sfdx force:source:deploy -u <yourOrgAlias> -w 10 --verbose -p force-app
```

ℹ️ You may also deploy only the main package (i.e. without the CRM Analytics) by targeting only the `default` folder 
```
sfdx force:source:deploy -u <yourOrgAlias> -w 10 --verbose -p force-app/main/default
```

### Quick Direct Deploy

For a quick and easy deployment, you may alternatively use the following deploy buttons
leveraging the **[GitHub Salesforce Deploy Tool](https://github.com/afawcett/githubsfdeploy)**
implemented by [Andrew Fawcett](https://andyinthecloud.com/2013/09/24/deploy-direct-from-github-to-salesforce/).

To deploy only the **main Apex package** to your Org, you may use the following button.

<a href="https://githubsfdeploy.herokuapp.com?ref=apexOnly">
  <img alt="Deploy main Apex Package to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

To deploy the **whole package** (i.e. with the CRM Analytics App) to your Org,
you may use the following button.<br/>
⚠️ **Beware** to have properly activated _CRM Analytics_ on your target Org and granted your
user the _CRM Analytics Admin_ rights before deploying the package.

<a href="https://githubsfdeploy.herokuapp.com?ref=master">
  <img alt="Deploy complete Package to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>


## Configuration

### Main Apex Package

Process configuration rely on custom setting or custom metadata records depending on the
schedulable tool.
* **Custom Setting** records are available for the Org Limits and Storage snapshots and basically
enable to set a data retention period (in days, everything being kept by default) and, for Org Limits,
to bypass some uninteresting limits (as a comma separated list of limit names).
* **Custom Metadata** records are available for the Picklist snapshot to define the set of
picklist fields to consider (the label of which should be in the `ObjectApiName.FieldApiName` format)

### CRM Analytics Application

ℹ️ The **SYS Monitoring** CRM Analytics App is shared with all users in admin mode by default
upon deploy. It is therefore important to immediately modify these settings after
deployment to prevent any data leak or dashboard corruption by unauthorized CRM Analytics users.

You also need to grant the **SYS_UseScheduleTools** permission set to the CRM Analytics
Integration user to let it access the snapshot objects.

At last, you need to configure and schedule the CRM Analytics connection to include the main
fields of the **SYS_OrgLimitSnapshot__c** and **SYS_OrgStorageSnapshot__c** objects: `Id`, `Name`,
`CreatedDate`, `RecordTypeId` (if any) and all custom fields.


## Scheduling

### Main Package Apex Scheduling

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

ℹ️ Via setup, it is only possible to schedule the snapshots on a daily basis at a given hour. If you want to schedule 
the **SYS_OrgLimitSnapshot_SCH** easily on an hourly basis, please run the following statement from _anonymous execution
window_ of the _dev console_.
```
String schedule = '0 0 * * * ?'; 
SYS_OrgLimitSnapshot_SCH job = new SYS_OrgLimitSnapshot_SCH(); 
system.schedule('Hourly Org Limits Snaphots', schedule, job);
```

### CRM Analytics Recipe Scheduling

Afte, having deployed the CRM Analytics package (and run the main package Apex at least once to
have actual data to ingest), you need to initialise first the **SYS Org Storage** and **SYS Org Limits** 
datasets by running the **SYS Monitoring Init** recipe.

![Dataset Initialisation](/media/DatasetInit.png)

Then, you may schedule the **SYS Monitoring** recipe to run automatically after the connection synch 
to automatically upsert the **SYS Org Storage** and **SYS Org Limits**. This recipe enables to
new source synched data to the history datasets.

![Dataset Upsert](/media/DatasetUpdate.png)


ℹ️ If you keep a long history in the **SYS_OrgLimitSnapshot__c** and **SYS_OrgStorageSnapshot__c** 
source objects, you may optimise the periodic dataset updates by filtering synced data to the most 
recent days.

⚠️ It is up to you to manage the history data actually kept in the target **SYS Org Storage** and
**SYS Org Limits** datasets. You may easily do it by adding a filtering node in the 
**SYS Monitoring** recipe before merging the current dataset with the new data rows.

By properly configuring the retention periods, you may e.g.
* keep only a 10 day sliding window of **Org Limit** data in the Salesforce core database
* keep 1 year of **Org Limit** data in CRM Analytics


## Multi-Org CRM Analytics Implementation

This package may be used in a multi-Org environment,
* the main package must be deployed and scheduled on each Org
* data produced in each Org may then be synched to a single **CRM Analytics** instance via standard  **connectors** or **external connectors**

The provided datasets and recipes may however be slightly adapted.

In the following example (leveraging legacy `dataflow` instead of `recipe`)
* the custom object records are ingested via `sfdcDigest` (local Org) or `digest` (remote Org) nodes
* `Org name` field is added and `record ID` field updated (to include Org Name) via `compute` nodes
* all records are then merged in a single dataset via an `append` node
* the resulting dataset is then stored via a final `register` node with the 2 additional fields.

![Data Aggregation DataFlow](/media/DataAggregation.png)

ℹ️ The provided dashboards may then simply be adapted to display and filter according to the additional `Org Name` property.