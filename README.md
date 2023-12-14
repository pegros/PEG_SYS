
# ![Logo](/media/logo.png) &nbsp; PEG SYS Components

## Introduction

The **PEG_SYS** package aims primarily at generating various Org monitoring data to be used either locally
(via standard reports and dashboards) or within **CRM Analytics** (e.g. for long history retention or in case
of multi-Org connections).

Via a set of schedulable Apex tools, it enables to take periodic snapshots of
* **Org limits** via the standard **[OrgLimit](https://developer.salesforce.com/docs/atlas.en-us.238.0.apexref.meta/apexref/apex_class_System_OrgLimit.htm)** Apex class
* **Org Storage** via the standard **Storage Usage** Setup page (accessible from the **System Overview** setup page)
* **Org Licenses** via the standard **UserLicense** and **PermissionSetLicense** objects (via SOQL queries)

It stores snapshot data in custom object records (`CreationDate` corresponding to the snapshot timestamp) and
automatically purges old ones based on configurable durations (per object).

It also addresses issues specific to **CRM Analytics** (or even **Marketing Cloud**), such as:
* **Picklist Values** extraction for code-to-label picklist value mapping in DataFlows/Recipes
(only the current situation of the configured picklist fields being stored, i.e. no history)
* **System Permissions** extraction for Profiles, Permission Set Groups and Permission Sets 
(only the current situation being stored, i.e. no history)
* **SObject** extraction from System metadata (only the current situation being stored, i.e. no history)

A **CRM Analytics** application is also provided to monitor the snapshots on a larger scale, with all 
the recipes required to initiate and update the underlying datasets.


## Standard Salesforce Application

A standard **SYS Monitoring** Application is provided and enables to access the standard custom objects
storing the snapshots.

![SYS Monitoring App](/media/MonitoringApp.png)

By default, object tabs and some list views are provided. this baseline may easily be 
extended by configuring additional list views or standard reports / dashboards.

ℹ️ The creation date of all **SYS** objects correspond to the snapshot timestamp.


### **Org Licenses**

This object contains snapshots fetched by SOQL queries on the standard **UserLicense**
and **PermissionSetLicense** objects. Record Types segregate the two data source.

![Org Licenses List View](/media/OrgLicenses.png)


### **Org Limits**

This object contains snapshots fetched via the standard **Apex OrgLimit API**.

![Org Limits List View](/media/OrgLimits.png)


### **Org Storage**

This object contains snapshots fetched by parsing the standard **Storage Usage** Setup page.
Multiple Record Types are available, segregating data corresponding to each of the table
available in this page. Field values are set depending on each Record Type, as well as the
meaning of the ratio. 

![Org Storage List View](/media/OrgStorage.png)


### **Picklist Values**

This object contains snapshots fetched by leveraging standard **Apex Schema.describe()** calls.
A unique name is generated concatenating the object, the field and the value code, enabling
to easily perform augment / join operations in **CRM Analytics** dataflows / recipes to set 
labels corresponding to picklist fields in datasets.

![Picklist List View](/media/Picklist.png)


### **(System) Permissions**

This object contains for Profiles, Permission Set Groups and Permission Sets the list of
active System Permissions (via `permission...` fields) in order to load them as records
in a **CRM Analytics** dataset.

![Picklist List View](/media/Permission.png)


### **Objects**

This object contains the list of all SObjects defined on the platform.

![Object List View](/media/Objects.png)


## CRM Analytics Application

A standard **CRM Analytics** Application is provided and enables to access various Dashboards
and Lenses leveraging the various snapshot objects.

![CRM Analytics Monitoring App](/media/AnalyticsMonitoringApp.png)

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


## Package Content

The package is split into two folders respectively containing
* the main Apex package (`default` folder)
* a sample CRM Analytics monitoring App (`analytics` folder)

### Main Package (`default` folder)

The main package contains the following main components:
* 4 Schedulable Apex classes (+ 4 related test classes)
    * **SYS_OrgLicenseSnapshot_SCH** to schedule and execute Org license snapshots
    * **SYS_OrgLimitSnapshot_SCH** to schedule and execute Org limit snapshots
    * **SYS_OrgStorageSnapshot_SCH** to schedule and execute Org Storage snapshots
    * **SYS_PicklistSnapshot_SCH** to schedule and execute Picklist Values snapshots
    * **SYS_PermissionSnapshot_SCH** to schedule and execute System Permission snapshots
    * **SYS_ObjectSnapshot_SCH** to schedule and execute SObject snapshots
* 6 Custom Objects (+ 6 associated tabs + 6 associated layouts)
    * **SYS_OrgLicenseSnapshot__c** to store Org License snapshot data
    * **SYS_OrgLimitSnapshot__c** to store Org limit snapshot data
    * **SYS_OrgStorageSnapshot__c** to store Org Storage snapshot data
    * **SYS_PicklistSnapshot__c** to store Picklist Value snapshot data
    * **SYS_PermissionSnapshot__c** to store System Permission snapshot data
    * **SYS_ObjectSnapshot__c** to store Object snapshot data
* 3 Custom Settings
    * **SYS_OrgLicenseConfig__c** to configure Org license snapshot process
    * **SYS_OrgLimitConfig__c** to configure Org limit snapshot process
    * **SYS_OrgStorageConfig__c** to configure Org Storage snapshot process
* 1 Custom Metadata
    * **SYS_PicklistLabel__mdt** to configure Picklist Field snapshot process
* 1 PermissionSet (+ 1 related layout)
    * **SYS_UseScheduleTools** to get all access rights necessary to run the schedulable
    Apex classes and access the snapshot data and configuration.

It also includes test elements for deployment:
* 1 Application
    * **SYS_Monitoring** providing access to the different **SYS** Object tabs
    * with its related (empty) utility bar flexipage
* 1 Static Resources
    * **SYS_OrgStorageSnapshot_TST** to be used as **Storage Usage** Setup page test content
* 1 Content Asset
    * **SYS_Logo** containing the logo displayed on the App (and **CRM Analytics** Dashboards)


### CRM Analytics Package (`wave` folder)

The CRM Analytics package contains the following components:
* 1 CRM Analytics App
    * **SYS Monitoring** containing all **SYS** datasets, dashboards and lenses
* 4 dashboards 
    * **SYS Org Licenses Monitoring** for licenses
    * **SYS Org Limits Monitoring** for limits
    * **SYS Org Storage Monitoring** for Storage
    * **SYS Org Permissions Analysis** for Permissions
* 1 lens 
    * **SYS Org Picklist Status** for picklist values
* 12 datasets
    * **SYS OrgLicenses** for licenses
    * **SYS OrgLimits** for limits
    * **SYS OrgStorage** for Storage
    * **SYS OrgPicklist** for picklist values
    * **SYS Profiles** for profiles
    * **SYS PermissionSetGroups** for permission set groups
    * **SYS PermissionSets** for permission sets
    * **SYS ObjectPermissions** for object access permissions
    * **SYS FieldPermissions** for field access permissions
    * **SYS SetupAccess** for Setup Entity permissions
    * **SYS SystemPermissions** for System permissions
    * **SYS TabSettings** for Tab Settings (in permissions)
* 8 recipes (+ 8 related dataflows required for metadata deployment), with different purposes
    * **SYS_Picklist_Label_Synch** simply overwrites the **SYS OrgPicklist** dataset
    * **SYS_Org_Permission_Synch** overwrites most of the **Permission** related datasets
    (from **SYS Profiles** to ** **SYS TabSettings**)
    * **SYS_Org_License_Monitoring_Init**, **SYS_Org_Limit_Monitoring_Init** and **SYS_Org_Storage_Monitoring_Init** enable to respectively initialise the **SYS OrgLicenses**, **SYS OrgLimits** and **SYS OrgStorage** datasets after
    initial synch (they should be run only once)
    * **SYS_Org_License_Monitoring**, **SYS_Org_Limit_Monitoring** and **SYS_Org_Storage_Monitoring** enable to respectively extend the **SYS OrgLicenses**, **SYS OrgLimits** and **SYS OrgStorage**
    datasets after each connection run to append new synched data (they should be schedule
    according to the connection used for each **SYS** custom object)


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

To deploy the **whole package** (i.e. with the CRM Analytics App) to your Org,
you may use the following button.<br/>
⚠️ **Beware** to have properly activated _CRM Analytics_ on your target Org and granted your
user the _CRM Analytics Admin_ rights before deploying the package.

<br/>

<a href="https://githubsfdeploy.herokuapp.com?ref=master">
  <img alt="Deploy complete Package to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

<br/>

To deploy only the **main Apex package** to your Org, you may use the following button instead.

<a href="https://githubsfdeploy.herokuapp.com?ref=apexOnly">
  <img alt="Deploy main Apex Package to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

<br/>
⚠️ **Beware**: When deploying a new version of the package, you will need to first unschedule the 
Apex class executions (and re-schedule them afterwards).

In order to easily unschedule all scheduled Apex class jobs of the **PEG_SYS** package,
please run the following statement from _anonymous execution window_ of the _dev console_.
```
List<AsyncApexJob> scheduledJobs = [SELECT  ApexClass.Name, CronTriggerId,
                                            CronTrigger.CronExpression 
                                    FROM AsyncApexJob 
                                    WHERE  JobType='ScheduledApex'
                                        AND CronTrigger.CronExpression != null
                                        AND ApexClass.Name LIKE 'SYS_%'];
if (scheduledJobs != null && scheduledJobs.size()>0) {
    for (AsyncApexJob iter : scheduledJobs) {
        System.abortJob(iter.CronTriggerId);
    }
}
```

After deployment, you may reschedule all your jobs via a command like the following.
```
String hourlySchedule = '0 0 * * * ?'; 
String dailySchedule = '0 0 1 * * ?'; 
String weeklySchedule = '0 0 1 ? * 1'; 

SYS_OrgLicenseSnapshot_SCH job1 = new SYS_OrgLicenseSnapshot_SCH(); 
system.schedule('Weekly Org License Snaphots', weeklySchedule, job1);

SYS_OrgLimitSnapshot_SCH job2 = new SYS_OrgLimitSnapshot_SCH(); 
system.schedule('Hourly Org Limits Snaphots', hourlySchedule, job2);

SYS_OrgStorageSnapshot_SCH job3 = new SYS_OrgStorageSnapshot_SCH(); 
system.schedule('Weekly Org Storage Snaphots', weeklySchedule, job3);

SYS_PicklistSnapshot_SCH job4 = new SYS_PicklistSnapshot_SCH(); 
system.schedule('Daily Picklist Snaphots', dailySchedule, job4);

SYS_PermissionSnapshot_SCH job5 = new SYS_PermissionSnapshot_SCH(); 
system.schedule('Daily Permission Snaphots', dailySchedule, job5);

SYS_ObjectSnapshot_SCH job6 = new SYS_ObjectSnapshot_SCH(); 
system.schedule('Daily Object Snaphots', dailySchedule, job6);
```

## Configuration

### Main Apex Package

Process configuration rely on _custom setting_ or _custom metadata_ records depending on the
schedulable tool.
* **Custom Setting** records
    * They are available for the Org Limits and Storage snapshots
    * They basically enable to set a data retention period (in days, everything being kept by default)
    * For Org Limits, it also enables to bypass some uninteresting limits (as a comma separated list of limit names).
* **Custom Metadata** records
    * They are available for the Picklist snapshot to define the set of picklist fields to consider
    * By default, the `MasterLabel` of `SYS_PicklistLabel` metadata records should be in the `ObjectApiName.FieldApiName` format to indicate which picklist to process.
    * As there is a label size limitation, it is possible to set this value in the `Picklist` field instead (in which case this information supersedes that in the `MasterLabel`)

⚠️ You also need to grant the **SYS_UseScheduleTools** permission set to all users requiring
access to the **SYS Monitoring** App or the **SYS** custom objects (especially the user scheduling
the snapshot Apex classes, see below).


### CRM Analytics Application

⚠️ The **SYS Monitoring** CRM Analytics App is shared with all users in admin mode by default
upon deploy. It is therefore important to immediately modify these settings after
deployment to prevent any data leak or dashboard corruption by unauthorized CRM Analytics users.

You also need to grant the **SYS_UseScheduleTools** permission set to the CRM Analytics
Integration user to let it access the **SYS** custom objects.

At last, you need to configure and schedule the CRM Analytics connection(s) to include the main
fields of the **SYS** objects: `Id`, `Name`, `CreatedDate`, `RecordTypeId` (if any)
and all custom fields.


## Scheduling

### Main Package Apex Scheduling

Snapshots may be **scheduled** independently via the standard `Schedule Apex` button displayed
in the **Apex Classes** Setup page.
* **SYS_OrgLicenseSnapshot_SCH** is usually scheduled once a week to really 
track visible evolution
* **SYS_OrgStorageSnapshot_SCH** is usually scheduled once a week to really 
track visible evolution
* **SYS_PicklistSnapshot_SCH** is usually scheduled once a day to track any evolution to 
the corresponding metadata (but it may be also be launched only manually after each new application
deployment)
* **SYS_PermissionSnapshot_SCH** is usually scheduled once a day to update the status
of System Permissions
* **SYS_OrgLimitSnapshot_SCH** may be scheduled multiple times per day (down to hourly) to get
finer view of the limit evolution (for now, there is a single schedule for all limits).

ℹ️ For now, **SYS_ObjectSnapshot_SCH** is implemented as a schedulable class but is rather meant 
for on-demand execution for analysis. It may be launched with the following command from the
developer console:
```
SYS_ObjectSnapshot_SCH.execute(null);
```

⚠️ **Beware** that the **SYS_PicklistSnapshot_SCH** schedulable will systematically fail
if bad Picklist names are registered in the `MasterLabel`of any **SYS_PicklistLabel__mdt** metadata
record in `active` status. It may thus be useful to check the configuration validity after any
modification by launching the following command from the developer console:
```
SYS_PicklistSnapshot_SCH.execute(null);
```

ℹ️ Via setup, it is only possible to schedule the snapshots on a daily basis at a given hour.
If you want to schedule the **SYS_OrgLimitSnapshot_SCH** easily on an hourly basis, please run
the following statement from _anonymous execution window_ of the _dev console_.
```
String schedule = '0 0 * * * ?'; 
SYS_OrgLimitSnapshot_SCH job = new SYS_OrgLimitSnapshot_SCH(); 
system.schedule('Hourly Org Limits Snaphots', schedule, job);
```


### CRM Analytics Recipe Scheduling

After having deployed and configured the CRM Analytics application (and run the main Apex schedulable classes
at least once to have actual data to ingest), you need to initialise the **SYS**
datasets by running the **Init** recipes.

![Dataset Initialisation](/media/SnapshotInitRecipe.png)

Then, you may then schedule the main **SYS** recipe to run automatically after connection synch 
to periodically upsert these **SYS** datasets. These recipe enables to add new synched data into
these history datasets.

![Dataset Upsert](/media/SnapshotUpdateRecipe.png)


⚠️ Beware to the **SYS_Picklist_Label_Synch**  and **SYS_Org_Permission_Synch** recipes
respectively for picklist values and permission data which work like the 
**Init** recipes but should be scheduled like the main ones.

![Dataset Upsert](/media/PicklistSynchRecipe.png)


ℹ️ Within **CRM Analytics**, you may use multiple connections to your Org with different schedules,
typically to synch:
* Org limits on an hourly basis
* Picklist values and Permissions on a daily basis
* Org License and Storage on a weekly basis


ℹ️ If you keep a long history in the **SYS** source custom objects, you may optimise
the periodic dataset updates by filtering synced data to the most recent days.

⚠️ It is up to you to manage the amount of history data actually kept in the main target **SYS**
datasets. You may easily do it by adding a filtering node in the main 
**SYS** recipes before merging the current dataset with the new data rows.

By properly configuring the retention periods in the Org and **CRM Analytics**, you may e.g.
* keep only a 10 day sliding window of **Org Limit** data in the Salesforce core database
* keep 1 year of **Org Limit** data in CRM Analytics


## Multi-Org CRM Analytics Implementation

This package may be used in a multi-Org environment,
* the main Apex package must be deployed and scheduled on each Org
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