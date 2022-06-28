/***
* @description      This class enables to take snapshots of Org Limit data
*                   at scheduled times and register them in custom Snapshot Object
*                   records.
* @author P-E GROS
* @date   June 2022
* @see PEG_SYS package (https://github.com/pegros/PEG_SYS)
* 
* MIT License
* 
* Copyright (c) 2022 pegros
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

public  without sharing class SYS_OrgLimitSnapshot_SCH implements Schedulable {

    /***
    * @description Custom Setting to configure the schedulable process.
    ***/
    static final public SYS_OrgLimitConfig__c SETTING = SYS_OrgLimitConfig__c.getInstance();

    /***
    * @description  Entry method for schedulable trigger.
    *               It takes new snapshots of all limits not bypassed (configured
    *               in the SYS_OrgLimitConfig__c custom setting) and registers them
    *               in the SYS_OrgLimitSnapshot__c custom object (standard CreatedDate 
    *               field corresponding to the snapshot timestamp and Name field 
    *               containing the name of the Limit).
    *               If configured in the configuration setting, it then also deletes
    *               all records older than a N days (configured in the SYS_OrgLimitConfig__c
    *               custom setting).
    * @param        context     Schedulable context (if any).
    * @Exception    none special.
    ***/
    public static void execute(SchedulableContext context) {
        System.debug('execute: START SYS_OrgLimitSnapshot_SCH');

        Set<String> limits2bypass = new Set<String>();
        if (String.isNotBlank(SETTING.BypassedLimits__c)) {
            System.debug('execute: registering limits to bypass ' + SETTING.BypassedLimits__c);
            limits2bypass = new Set<String>(SETTING.BypassedLimits__c.split(','));
            System.debug('execute: bypassed limits registered ' + limits2bypass);
        }
        else {
            System.debug('execute: no limit to bypass');
        }

        /*ID orgID = UserInfo.getOrganizationId();
        System.debug('execute: orgID fetched ' + orgID);
        String orgName = UserInfo.getOrganizationName();
        System.debug('execute: orgName fetched ' + orgName);*/

        Map<String,System.OrgLimit> limitMap = OrgLimits.getMap();
        System.debug('execute: Map fetched with size ' + limitMap.size());

        List<SYS_OrgLimitSnapshot__c> newSnapshots = new List<SYS_OrgLimitSnapshot__c>();
        for (String iter : limitMap.keySet()) {
            if (limits2bypass.contains(iter)) {
                System.debug('execute: bypassing limit ' + iter);
            }
            else {
                System.debug('execute: processing limit ' + iter);
                System.OrgLimit iterLimit = limitMap.get(iter);
                System.debug('execute:   --> ' + iterLimit);
                newSnapshots.add(new SYS_OrgLimitSnapshot__c(
                    Name = iter,
                    Value__c = iterLimit.getValue(),
                    Limit__c = iterLimit.getLimit()
                ));
            }
        }

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
            List<SYS_OrgLimitSnapshot__c> snapshots2delete =
                [select Id from SYS_OrgLimitSnapshot__c where CreatedDate < :purgeLimit];
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

        System.debug('execute: END SYS_OrgLimitSnapshot_SCH');
    }
}