# ![Logo](/media/logo.png) &nbsp; **CRM Analytics** Package

## Introduction

As an interesting add-on feature for the Orgs having **CRM Analytics** licenses available, 
the **PEG_SYS** package offers a set of **CRM Analytics** dashboards with related datasets
and recipes to synch the **PEG_SYS** custom objects from the core platform.

All these elements are grouped into a single **CRM Analytics** Application.

![CRM Analytics Monitoring App](/media/AnalyticsMonitoringApp.png)

ℹ️ Installation of the **[Apex](/help/sysApex.md)** package is a prerequisite.


## CRM Analytics Dasboards & Lenses

###  **Org Licenses**

For the licenses, a simple dashboard is provided to monitor the evolution
of license consumption for User or Permission Set licenses over a period. 

![Org Limit Analytics Dashboard](/media/OrgLimitsMonitoring.png)


###  **Org Limits**

For the governor limits, a simple dashboard is provided to monitor the evolution
of their values over a period. Granularity is hourly to provide more details
of consumption peaks within a day.

![Org Limit Analytics Dashboard](/media/OrgLimitsMonitoring.png)


### **Org Storage**

For the storage, a simple dashboard is provided to monitor the evolution
of storage over a period. Different tabs enable to get details about 
the different types of storage and top consuming Users.

![Org Limit Analytics Dashboard](/media/OrgStorageMonitoring.png)


### **Picklist Values**

For the picklist values, a simple Lens is provided to control the actual set of 
values synched within **CRM Analytics**.

![Org Picklist Analytics Lens](/media/PicklistValuesControl.png)


### **Permission Analysis**

For the Profiles, Permission Set Groups and Permission Sets, a complex dashboard is provided
to analyse each dimension of the permissions granted by each item within **CRM Analytics**:
object and field accesses, system permissions, setup entity accesses...

![Permissions Analytics Dashboard](/media/PermissionsAnalysis.png)


### **Setup Audit Trail Analysis**

For the Setup Audit Trail, a simple dashboard is provided to query through
the possibly large amount of Setup Audit Trail events, e.g. by focusing on a
specific User or operation.

![Setup Audit Trail Analytics Dashboard](/media/SetupAuditTrailMonitoring.png)


## Package Configuration

### Access to Snapshot Objects

You need to grant the **SYS_UseScheduleTools** permission set to the **CRM Analytics** integration
user in order to be able to synch all snapshot records.

You also need to execute and schedule the different **Apex** schedulable classes to generate and update
records within the **SYS** custom objects on the core platform.


### Historized Datasets

Some of the datasets are designed to keep data history even after the source **SYS** custom object
records have been purged.
* **SYS_OrgLicenses**
* **SYS_OrgLimits**
* **SYS_OrgStorage**

For each of these datasets, a specific recipe is available (with `_Init` name suffix) is available 
to initialize them. This is a mandatory step, as the standard synch recipes will otherwise systematically 
fail. 

![Dataset Initialisation](/media/SnapshotInitRecipe.png)

Once the required datasets have been initialized, you may run and schedule their synch **SYS** recipes
(same name without `_Init` name suffix), which enable to add new synched data into these historized datasets.

![Dataset Upsert](/media/SnapshotUpdateRecipe.png)

All these recipes are independent and may be have different schedules, aligned to the scheduling of their
related **Apex** schedulable classes (e.g. hourly for **SYS_OrgLimits** vs weekly for the others).


### Non-Historized Datasets

Some datasets have no initialization prerequisite:
* **SYS_OrgPicklist**
* **SYS_SetupAuditTrail**
* Permission related datasets
    * **SYS_Profiles**
    * **SYS_PermissionSetGroups**
    * **SYS_PermissionSets**
    * **SYS_ObjectPermissions**
    * **SYS_FieldPermissions**
    * **SYS_OrgPermissions**
    * **SYS_SystemPermissions**
    * **SYS_SetupAccess**
    * **SYS_TabSettings**

For these datasets, synch recipes are available (only one for all Permission datasets) and 
Once the required datasets have been initialized, you may run and schedule their synch **SYS** recipes
(same name without `_Init` name suffix), which enable to add new sy
⚠️ Beware to the **SYS_Picklist_Label_Synch**  and **SYS_Org_Permission_Synch** recipes
respectively for picklist values and permission data which work like the 
**Init** recipes but should be scheduled like the main ones.

![Dataset Upsert](/media/PicklistSynchRecipe.png)

All these recipes are independent and may be have different schedules, aligned to the scheduling of their
related **Apex** schedulable classes (usually daily for all of them).


### Snapshot Data Retention

This section only applies to the historized **SYS** datasets.

If you keep a long history in the source custom objects on the core platform, you may optimise
the periodic dataset updates by filtering synched data to the most recent days.

⚠️ By default, the synch recipes keep adding new records in the historized datasets.
* It is up to you to manage the actual amount of history data actually kept in them.
* You may easily do it by adding a filtering node in their synch recipes to remove old
data rows from the current dataset before merging it with the new data rows synched.

By properly configuring the retention periods in the Org and **CRM Analytics**, you may e.g.
* keep only a 10 day sliding window of **SYS_OrgLimitSnapshot__c** data in the Salesforce core database
* keep 1 year of **SYS_OrgLimits** data in CRM Analytics


### Multi-Org Implementation

This package may be used in a multi-Org environment,
* the main **[Apex](/help/sysApex.md)** package must be deployed and scheduled on each Org
* data produced in each Org may then be synched to a single **CRM Analytics** instance via standard **connectors** or **external connectors**

The provided datasets and recipes however need to be slightly adapted.
In the following example (leveraging legacy `dataflow` instead of `recipe`)
* the custom object records are ingested via `sfdcDigest` (local Org) or `digest` (remote Org) nodes
* `Org name` field is added and `record ID` field updated (to include Org Name) via `compute` nodes
* all records are then merged in a single dataset via an `append` node
* the resulting dataset is then stored via a final `register` node with the 2 additional fields.

![Multi-Org Aggregation DataFlow](/media/MultiOrgAggregation.png)

ℹ️ The provided dashboards also need to be slightly adapted to display and filter according to
the additional `Org Name` property.


## Package Content

The **CRM Analytics** add-on package is stored in the `analytics` folder of the **PEG_SYS** repository.
It contains the following metadata
* 1 Application (**SYS Monitoring**)
* datasets (with related XMDs)
* recipes (+ related dataflows) to synchronize the different datasets (and initialize some of them)
* Dashboards (with related XMDs) and Lenses
* 1 Content Asset (with the **SYS_Logo** App logo shared with the **CRM Analytics** App)

ℹ️ The standard `wave` folder has been split into subfolders by metadata type for more clarity.