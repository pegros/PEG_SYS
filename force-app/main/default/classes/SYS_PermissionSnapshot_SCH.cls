/***
* @description      This class enables to take snapshots of permissions within all
*                   Profiles and PermissionSets of an Org and store them in custom
*                   object records, providing an easier ability for sensitive 
*                   permission monitoring.
* @author P-E GROS
* @date   Dec 2023
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

public without sharing class SYS_PermissionSnapshot_SCH  implements Schedulable {

    /***
    * @description Name Prefix of Permission Fields on the the PermissionSet standard Object.
    ***/
    static final private String PERM_FIELD_PREFIX = 'Permissions';

    /***
    * @description Number of PermissionSets processed per upsert operation (max 200)
    ***/
    static final public Integer MAX_UPSERT_PSETS = 200;

    /***
    * @description Number of PermissionSnapshot__c rows deleted per delete operation.
    ***/
    static final public Integer MAX_DELETE_SNAPSHOTS = 2000;

    /***
    * @description Permissions bypassed because of technical SOQL constraint (fields not accessible)
    ***/
    static final private Set<String> IGNORED_PERMISSIONS = new Set<String>{
        'PermissionsInstallMultiforce','PermissionsPublishMultiforce','PermissionsCreateMultiforce'};
    

    /***
    * @description  Entry method for schedulable trigger.
    *               It triggers a queueable process to analyse all configured 
    *               PermissionSets and register all permission fields set active
    *               on them in the SYS_PermissionSnapshot__c custom object.
    *               There is no historisation, the new snapshot replacing the
    *               previous one.
    * @param        context     Schedulable context (if any).
    * @Exception    none
    ***/
    public static void execute(SchedulableContext context) {
        System.debug('execute: START SYS_PermissionSnapshot_SCH');

        List<String> permissionFields = getPermissionFields();
        System.debug('execute: #permission fields extracted ' + permissionFields.size());

        System.enqueueJob(new SYS_PermissionSnapshot_QUE(permissionFields));
        System.debug('execute: END SYS_PermissionSnapshot_SCH / queueable enqueued');
    }

    /***
    * @description  Utility method to extract the list of all boolean permission fields
    *               defined on the Org for the standard Permission object.
    * @return       List<String>    List of Permission field API Names
    * @Exception    none
    ***/

    @TestVisible
    private static List<String> getPermissionFields() {
        System.debug('initPermissionFields: START with permission field prefix ' + PERM_FIELD_PREFIX);

        List<String> fieldList = new List<String>();
        for (Schema.SObjectField  iter : Schema.SObjectType.Profile.fields.getMap().values()) {
            String iterName = iter.getDescribe().getName();
            if (iterName.startsWith(PERM_FIELD_PREFIX)) {
                if (IGNORED_PERMISSIONS.contains(iterName)) {
                    system.debug(LoggingLevel.FINER,'initPermissionFields: bypassing ' + iterName);   
                }
                else {
                    system.debug(LoggingLevel.FINE,'initPermissionFields: registering ' + iterName);   
                    system.debug(LoggingLevel.FINEST,'initPermissionFields: of type ' + iter.getDescribe().getType());   
                    fieldList.add(iterName);
                }
            } 
            else {
                system.debug(LoggingLevel.FINEST,'initPermissionFields: ignoring ' + iterName);   
            }
        }

        System.debug('initPermissionFields: END returning #Fields ' + fieldList.size());
        return fieldList;
    }


    /***
    * @description  Queueable Subclass to handle cases to initialize/review snapshots
    *               of picklist field labels in asynchronous mode.
    *               It upserts SYS_PermissionSnapshot__c records based on all 
    *               permission field values for all Permission sets.
    *               It stops when all PermissionSet records have been 
    *               processed, individual executions being stopped as soon as MAX_ROWS
    *               PermissionSet are processed, processing being requeued
    *               until there is no PermissionSet record to process.
    *               All SYS_PermissionSnapshot__c records not upserted by the process
    *               are then automatically deleted.
    **/

    public class SYS_PermissionSnapshot_QUE implements Queueable {

        /***
        * @description Queueable Operation context parameters
        ***/
        private List<String>    permFieldList;
        private DateTime        processStartTS;
        private ID              lastPSetID;

        /***
        * @description  Constructor for Queueable process init
        ***/
        public SYS_PermissionSnapshot_QUE(List<String> permFieldList) {
            System.debug('constructor: START SYS_PermissionSnapshot_QUE (init)');
            this.permFieldList = permFieldList;
            System.debug('constructor: #Permission Fields registered ' + permFieldList.size());
            this.processStartTS = DateTime.now();
            System.debug('constructor: processStartTS init ' + processStartTS);
            System.debug('constructor: START SYS_PermissionSnapshot_QUE (init)');
        }
        
        /***
        * @description  Constructor for Queueable process requeue
        ***/
        @TestVisible
        private SYS_PermissionSnapshot_QUE(List<String> permFieldList, DateTime processStartTS, ID lastPSetID) {
            System.debug('constructor: START SYS_PermissionSnapshot_QUE (requeue)');
            this.permFieldList = permFieldList;
            System.debug('constructor: #Permission Fields provided ' + permFieldList.size());
            this.processStartTS = processStartTS;
            System.debug('constructor: processStartTS provided ' + processStartTS);
            this.lastPSetID = lastPSetID;
            System.debug('constructor: lastPSetID provided ' + lastPSetID);
            System.debug('constructor: END SYS_PermissionSnapshot_QUE (requeue)');
        }

        /***
        * @description  Main Queueable Execution logic : upsert is processed in priority
        *               then old snapshots deletion; queueable is requeue if MAX_DELETE_SNAPSHOTS
        *               snapshot records is not reached.
        ***/
        public void execute(QueueableContext context) {
            System.debug('execute: START SYS_PermissionSnapshot_QUE');

            Boolean doRequeue = false;
            if (doUpsertPermissions()) {
                System.debug('execute: requeueing for further permissions upserts');
                doRequeue = true;
            }
            else if (doPurgeOldPermissions()) {
                System.debug('execute: requeueing for further permissions upserts');
                doRequeue = true;
            }

            if (doRequeue) {
                System.debug('execute: END SYS_PermissionSnapshot_QUE / requeuing for further processing');
                if (!Test.isRunningTest()) {
                    System.enqueueJob(new SYS_PermissionSnapshot_QUE(this.permFieldList, this.processStartTS, this.lastPSetID));
                }
            }
            else {
                System.debug('execute: END SYS_PermissionSnapshot_QUE / no requeue');
            }
        }

        /***
        * @description  Private Utility method to process PermissionSnapshot__c upsert logic.
        *               PermissionSets are processed by ascending record ID.
        *               Return true if PermissionSets have been processed.
        *               Updates the lastPSetID based on the last PermissionSet processed.
        ***/

        private Boolean doUpsertPermissions() {
            system.debug('doUpsertPermissions: START');

            // this.permFieldList
            //List<PermissionSet> pset2analyse = [    SELECT Profile.Name, PermissionSetGroup.Name, FIELDS(ALL)
            String psetQuery = 'SELECT Name,Profile.Name,PermissionSetGroupId,PermissionSetGroup.DeveloperName,' + String.join(this.permFieldList,',') 
                             + ' FROM PermissionSet' 
                             + (String.isBlank(this.lastPSetID) ? '' : ' WHERE Id > \'' + this.lastPSetID + '\'')
                             + ' ORDER BY Id'
                             + ' LIMIT ' + SYS_PermissionSnapshot_SCH.MAX_UPSERT_PSETS;
            String fieldList = String.join(this.permFieldList,',') + ',Profile.Name';
            system.debug('doUpsertPermissions: query prepared ' + psetQuery);
            /*List<PermissionSet> pset2analyse = [    SELECT FIELDS(ALL)
                                                    FROM PermissionSet
                                                    WHERE Id > :this.lastPSetID
                                                    ORDER BY Id
                                                    LIMIT :SYS_PermissionSnapshot_SCH.MAX_UPSERT_PSETS ];*/
            List<PermissionSet> pset2analyse = database.query(psetQuery);
            system.debug('doUpsertPermissions: #psets fetched ' + pset2analyse.size());

            if (pset2analyse == null || pset2analyse.isEmpty()) {
                system.debug('doUpsertPermissions: END / No PermissionSet snapshot to upsert');
                return false;
            }

            List<SYS_PermissionSnapshot__c> newPsetSnapshots = new List<SYS_PermissionSnapshot__c>();
            for (PermissionSet iter : pset2analyse) {
                system.debug(LoggingLevel.FINE,'doUpsertPermissions: processing PermissionSet ' + iter.Name);

                for (String iterField : this.permFieldList) {
                    if ((Boolean)(iter.get(iterField))) {
                        system.debug(LoggingLevel.FINE,'doUpsertPermissions: registering field ' + iterField);
                        newPsetSnapshots.add(new SYS_PermissionSnapshot__c(
                            Name = iterField,
                            PermissionSetId__c = iter.Id,
                            PermissionSet__c = iter.Name,
                            ProfileId__c = iter.ProfileId,
                            Profile__c = iter.Profile.Name,
                            PermissionSetGroupId__c = iter.PermissionSetGroupId,
                            PermissionSetGroup__c = iter.PermissionSetGroup.DeveloperName,
                            UniqueId__c =  iter.Id + '-' + iterField
                        ));
                    }
                    else {
                        system.debug(LoggingLevel.FINEST,'doUpsertPermissions: ignoring field ' + iterField);
                    }
                    this.lastPSetID = iter.Id;
                }
            }
            system.debug('doUpsertPermissions: #PsetSnapshots extracted ' + newPsetSnapshots.size());
            system.debug('doUpsertPermissions: last Pset ID updated ' + this.lastPSetID);

            upsert newPsetSnapshots UniqueID__c;
            System.debug('execute: END / PSetSnapshots upserted');
            return true;
        }


        /***
        * @description  Private Utility method to process PermissionSnapshot__c purge logic.
        *               All PermissionSnapshot__c with a SystemModStamp earlier than processStartTS
        *               are deleted.
        *               Return true if PermissionSnapshot__c have been purged.
        ***/

        private Boolean doPurgeOldPermissions() {
            system.debug('doPurgeOldPermissions: START');

            List<SYS_PermissionSnapshot__c> snapshots2purge = [ SELECT Id
                                                                FROM SYS_PermissionSnapshot__c
                                                                WHERE SystemModStamp <= :this.processStartTS
                                                                LIMIT :SYS_PermissionSnapshot_SCH.MAX_DELETE_SNAPSHOTS ];
            system.debug('doPurgeOldPermissions: #PsetSnapshots fetched ' + snapshots2purge.size());

            if (snapshots2purge == null || snapshots2purge.isEmpty()) {
                system.debug('doPurgeOldPermissions: END / No PermissionSet snapshot to delete');
                return false;
            }

            delete snapshots2purge;
            System.debug('doPurgeOldPermissions: END / PSet Snapshots deleted');
            return true;
        }
    }
}
