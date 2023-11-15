/***
* @description      This class enables to take snapshots of Org User License and PermissionSet License data
*                   at scheduled times and register them in custom Snapshot Object records.
* @author P-E GROS
* @date   Nov 2023
* @see PEG_SYS package (https://github.com/pegros/PEG_SYS)
* 
* MIT License
* 
* Copyright (c) 2023 pegros
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
***/

public without sharing class SYS_OrgLicenseSnapshot_SCH implements Schedulable {

    /***
    * @description Custom Setting to configure the schedulable process.
    ***/
    static final public SYS_OrgLicenseConfig__c SETTING = SYS_OrgLicenseConfig__c.getInstance();
    
    /***
    * @description  Record Type IDs for snapshot records
    ***/
    static private final String RT_ID_USER      = Schema.SObjectType.SYS_OrgLicenseSnapshot__c.getRecordTypeInfosByDeveloperName().get('UserLicense').getRecordTypeId();
    static private final String RT_ID_PERM_SET  = Schema.SObjectType.SYS_OrgLicenseSnapshot__c.getRecordTypeInfosByDeveloperName().get('PermissionSetLicense').getRecordTypeId();
    
    /***
    * @description  Entry method for schedulable trigger.
    *               It takes new snapshots of all UserLicense and PermissionSetLicense
    *               and registers them in the SYS_OrgLicenseSnapshot__c custom object
    *               (standard CreatedDate field corresponding to the snapshot timestamp
    *               and Name field containing the label of the license).
    *               Separate record types are applied respectively for UserLicense and
    *               PermissionSetLicense related records.
    *               If configured in the configuration setting, it then also deletes
    *               all records older than a N days (configured in the SYS_OrgLicenseConfig__c
    *               custom setting).
    * @param        context     Schedulable context (if any).
    * @Exception    none special.
    ***/
    public static void execute(SchedulableContext context) {
        System.debug('execute: START SYS_OrgLicenseSnapshot_SCH');
        List<SYS_OrgLicenseSnapshot__c> newSnapshots = new List<SYS_OrgLicenseSnapshot__c>();

        for (UserLicense iter : [Select LicenseDefinitionKey, MasterLabel, Name, Status, TotalLicenses, UsedLicenses from UserLicense]) {
            System.debug('execute: processing user license ' + iter.MasterLabel);
            newSnapshots.add(new SYS_OrgLicenseSnapshot__c(
                RecordTypeId = RT_ID_USER,
                Name = iter.MasterLabel,
                LicenseKey__c = iter.LicenseDefinitionKey,
                //MonthlyLoginsEntitlement__c = iter.MonthlyLoginsEntitlement,
                //MonthlyLoginsUsed__c = iter.MonthlyLoginsUsed,
                Status__c = iter.Status,
                TotalLicenses__c = iter.TotalLicenses,
                UsedLicenses__c = iter.UsedLicenses
            ));
        }
        System.debug('execute: all UserLicense processed');

        for (PermissionSetLicense iter : [Select PermissionSetLicenseKey, MasterLabel, ExpirationDate, DeveloperName, Status, TotalLicenses, UsedLicenses from PermissionSetLicense]) {
            System.debug('execute: processing pset license ' + iter.MasterLabel);
            newSnapshots.add(new SYS_OrgLicenseSnapshot__c(
                RecordTypeId = RT_ID_PERM_SET,
                Name = iter.MasterLabel,
                LicenseKey__c = iter.PermissionSetLicenseKey,
                ExpirationDate__c = iter.ExpirationDate,
                Status__c = iter.Status,
                TotalLicenses__c = iter.TotalLicenses,
                UsedLicenses__c = iter.UsedLicenses
            ));
        }
        System.debug('execute: all PermissionSetLicense processed');

        if (newSnapshots.size() > 0) {
            System.debug('execute: inserting #snapshots ' + newSnapshots.size());
            insert newSnapshots;
        }
        else {
            System.debug('execute: no snapshots to insert');
        }

        if ((SETTING.PurgeAfterDays__c != null) &&  (SETTING.PurgeAfterDays__c > 0)) {
            System.debug('execute: purging old snapshot records');

            Date purgeLimit = System.today().addDays(- ((Integer)(SETTING.PurgeAfterDays__c)));
            System.debug('execute: purgeLimit set to ' + purgeLimit);
            List<SYS_OrgLicenseSnapshot__c> snapshots2delete =
                [select Id from SYS_OrgLicenseSnapshot__c where CreatedDate < :purgeLimit];
            if (snapshots2delete?.size() > 0) {
                System.debug('execute: deleting #snapshots ' + snapshots2delete.size());
                delete snapshots2delete;
            }
            else {
                System.debug('execute: no snapshots to purge');
            }
        }
        else {
            System.debug('execute: no purge configured');
        }

        System.debug('execute: END SYS_OrgLicenseSnapshot_SCH');
    }
}