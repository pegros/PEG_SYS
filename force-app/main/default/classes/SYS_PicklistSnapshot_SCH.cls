/***
* @description      This class enables to take snapshots of picklist field value labels
*                   (via schema describes) at scheduled times and register them in custo
*                   Snapshot Object records.
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

public without sharing class SYS_PicklistSnapshot_SCH  implements Schedulable {

    /***
    * @description Number of upsert rows after which a new queueable execution is triggered.
    ***/
    static final private Integer MAX_ROWS = 1000;

    /***
    * @description Number of delete rows after which a new queueable execution is triggered.
    ***/
    static final private Integer MAX_DELETE_ROWS = 1000;

    /***
    * @description  Entry method for schedulable trigger.
    *               It takes new snapshots of all picklist labels (configured
    *               in the SYS_PicklistLabel__mdt custom metadata) and registers them
    *               in the SYS_PicklistSnapshot__c custom object.
    *               There is no historisation, the new snapshot replacing the
    *               previous one (label changes, new value add, old values removal).
    *               The tool first checks that all active SYS_PicklistLabel__mdt records
    *               are correct and, if OK, launches a SYS_PicklistSnapshot_QUE queueable
    *               asynchronous process to update the snapshot.
    * @param        context     Schedulable context (if any).
    * @Exception    DmlExceptions raised from the checkPicklists() execution.
    ***/
    public static void execute(SchedulableContext context) {
        System.debug('execute: START SYS_PicklistSnapshot_SCH');

        List<SYS_PicklistLabel__mdt> picklistList  = [  SELECT MasterLabel, Picklist__c FROM SYS_PicklistLabel__mdt WHERE isActive__c = true ];
        if (Test.isRunningTest()) {
            picklistList = new List<SYS_PicklistLabel__mdt>();
            picklistList.add(new SYS_PicklistLabel__mdt(MasterLabel = 'Opportunity.StageName'));
        }
        System.debug('execute: picklist list fetched with #items ' + picklistList.size());

        if ((picklistList == null) || (picklistList.isEmpty())) {
            System.debug('execute: END SYS_PicklistSnapshot_SCH / no picklist to process');
            return;
        }

        checkPicklists(picklistList);
        System.debug('execute: picklist to process checked');

        List<AggregateResult> currentStatus = [SELECT max(SystemModStamp) TS, count(Id) NUM FROM SYS_PicklistSnapshot__c];
        System.debug('execute: currentStatus fetched' + currentStatus);
        DateTime lastExecTS = (DateTime) ((currentStatus[0])?.get('TS'));
        System.debug('execute: last run fetched ' + lastExecTS);

        System.enqueueJob(new SYS_PickListSnapshot_QUE(picklistList,lastExecTS));
        System.debug('execute: END SYS_PicklistSnapshot_SCH / queueable enqueued');
    }

    /***
    * @description  Utility method to control the validity of a set of SYS_PicklistLabel__mdt
    *               records. Exceptions are thrown if the MasterLabel is improperly formated
    *               (should be "ObjectApiName.FieldApiName"), if the Object is not found,
    *               if the field is not found and if the field is not of picklist type.
    * @param        picklistList     List of Picklist metadata configurations to check.
    * @Exception    DmlExceptions raised from the checkPicklists() execution.
    ***/

    @TestVisible
    private static void checkPicklists(List<SYS_PicklistLabel__mdt> picklistList) {
        System.debug('checkPicklists: START with #items ' + picklistList.size());
        Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();

        for (SYS_PicklistLabel__mdt iter : picklistList) {
            system.debug('checkPicklists: processing picklistIter '  +  iter.MasterLabel);
            system.debug('checkPicklists: with picklist property '  +  iter.Picklist__c);
            
            String[] nameParts = (String.isEmpty(iter.Picklist__c) ? iter.MasterLabel.split('\\.') : iter.Picklist__c.split('\\.'));
            system.debug('checkPicklists: nameParts extracted '  + nameParts);
            if (nameParts.size() != 2) {
                system.debug(LoggingLevel.ERROR,'checkPicklists: invalid picklist name in configuration ' + iter.MasterLabel);
                throw new DmlException('Invalid picklist name configured: ' +  iter.MasterLabel);
            } 

            Schema.DescribeSObjectResult objectDesc = globalDesc.get(nameParts[0])?.getDescribe();
            system.debug('checkPicklists: objectDesc fetched '  + objectDesc);
            if (objectDesc == null) {
                system.debug(LoggingLevel.ERROR,'checkPicklists: invalid Object Name found in configured picklist name ' + iter.MasterLabel);
                throw new DmlException('Invalid Object Name found in configured picklist name ' +  iter.MasterLabel);
            }

            Schema.DescribeFieldResult fieldDesc   = objectDesc.fields.getMap().get(nameParts[1])?.getDescribe();
            system.debug('checkPicklists: fieldDesc fetched ' + fieldDesc);
            if (fieldDesc == null) {
                system.debug(LoggingLevel.ERROR,'checkPicklists: invalid field name found in configured picklist name '  +  iter.MasterLabel);
                throw new DmlException('Invalid field name found in configured picklist name ' +  iter.MasterLabel);
            }

            List<Schema.PicklistEntry>  fieldValues = fieldDesc.getPicklistValues();
            system.debug('execute: fieldValues fetched with size '  + fieldValues.size());
            if (fieldValues.isEmpty()) {
                system.debug(LoggingLevel.ERROR,'checkPicklists: non picklist field name found in configured picklist '  +  iter.MasterLabel);
                throw new DmlException('Non picklist field name found in configured picklist ' +  iter.MasterLabel);
            }
        }
        System.debug('checkPicklists: END OK');
    }


    /***
    * @description  Queueable Subclass to handle cases to initialize/review snapshots
    *               of picklist field labels in asynchronous mode.
    *               It analyses SYS_PicklistLabel__mdt records and upserts 
    *               SYS_PicklistSnapshot__c records based on all picklist field values.
    *               It stops when all SYS_PicklistLabel__mdt records have been 
    *               processed, individual executions being stopped as soon as MAX_ROWS
    *               SYS_PicklistSnapshot__c are processed, processing being requeued
    *               with the remainder of picklist fields.
    *               The list of picklist label metadata entries is assumed to have been
    *               controlled (see checkPicklists() method) prior to launching the 
    *               queueable.
    **/

    public class SYS_PicklistSnapshot_QUE implements Queueable {

        private List<SYS_PicklistLabel__mdt> picklistList;
        private DateTime lastExecTS;
        private Boolean  doFinalPurge;

        public SYS_PicklistSnapshot_QUE(List<SYS_PicklistLabel__mdt> picklistList, DateTime lastExecTS) {
            System.debug('constructor: START SYS_PicklistSnapshot_QUE (standard)');
            System.debug('constructor: #picklists provided ' + picklistList.size());
            this.picklistList = picklistList;
            System.debug('constructor: lastExecTS provided ' + lastExecTS);
            this.lastExecTS = lastExecTS;
            this.doFinalPurge = false;
            System.debug('constructor: END SYS_PicklistSnapshot_QUE (standard)');
        }

        public SYS_PicklistSnapshot_QUE(DateTime lastExecTS) {
            System.debug('constructor: START SYS_PicklistSnapshot_QUE (final purge)');
            System.debug('constructor: lastExecTS provided ' + lastExecTS);
            this.lastExecTS = lastExecTS;
            this.doFinalPurge = true;
            System.debug('constructor: END SYS_PicklistSnapshot_QUE (final purge)');
        }

        public void execute(QueueableContext context) {
            System.debug('execute: START SYS_PicklistSnapshot_QUE');

            if (this.doFinalPurge) {
                System.debug('execute: performing final purging');
                purgeOldPicklists();
            }
            else {
                System.debug('execute: performing picklist updates');
                upsertPicklists();
            }

            System.debug('execute: END SYS_PicklistSnapshot_QUE');
        }

        private void upsertPicklists() {
            System.debug('upsertPicklists: START');

            List<SYS_PicklistSnapshot__c> newSnapshots = new List<SYS_PicklistSnapshot__c>();         
            List<String> processedFields = new List<String>();

            Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();
            Boolean doContinue = !(this.picklistList.isEmpty());

            while (doContinue) {
                SYS_PicklistLabel__mdt iter = this.picklistList.remove(0);
                system.debug('upsertPicklists: processing picklistIter '  +  iter.MasterLabel);
                system.debug('upsertPicklists: with picklist property '  +  iter.Picklist__c);
                processedFields.add(iter.MasterLabel);

                String iterName = (String.isEmpty(iter.Picklist__c) ? iter.MasterLabel : iter.Picklist__c);
                String[] nameParts = iterName.split('\\.');
                system.debug('upsertPicklists: nameParts extracted '  + nameParts);
                Schema.DescribeSObjectResult objectDesc = globalDesc.get(nameParts[0])?.getDescribe();
                system.debug('upsertPicklists: objectDesc fetched '  + objectDesc);
                Schema.DescribeFieldResult fieldDesc   = objectDesc.fields.getMap().get(nameParts[1])?.getDescribe();
                system.debug('upsertPicklists: fieldDesc fetched ' + fieldDesc);
                
                List<Schema.PicklistEntry>  fieldValues = fieldDesc.getPicklistValues();
                system.debug('upsertPicklists: fieldValues fetched with size '  + fieldValues.size());

                for(Schema.PicklistEntry iterValue : fieldValues) {
                    system.debug(LoggingLevel.FINE,'upsertPicklists: processing picklist value ' + iterValue);
                    newSnapshots.add(new SYS_PicklistSnapshot__c(
                        Name        = (iterName + '.' + iterValue.getValue()).left(80),
                        UniqueID__c = iterName + '.' + iterValue.getValue(),
                        Picklist__c = iterName,
                        Object__c   = nameParts[0],
                        Field__c    = nameParts[1],
                        Code__c     = iterValue.getValue(),
                        Label__c    = iterValue.getLabel(),
                        IsActive__c = iterValue.isActive(),
                        IsDefault__c = iterValue.isDefaultValue()
                    ));
                }
                System.debug('upsertPicklists: newPicklists updated to #items ' + newSnapshots.size());

                if (newSnapshots.size() > MAX_ROWS ) {
                    System.debug('upsertPicklists: end of queueable process reached');
                    doContinue = false;
                }
                else if (this.picklistList.isEmpty()) {
                    System.debug('upsertPicklists: end of picklist list reached');
                    doContinue = false;
                }
            }
            System.debug('upsertPicklists: all/max picklists processed with #items ' + processedFields.size());
         
            upsert newSnapshots UniqueID__c;
            System.debug('upsertPicklists: newSnapshots upserted');

            if (this.lastExecTS != null) {
                List<SYS_PicklistSnapshot__c> oldSnapshots = [
                    SELECT Id FROM SYS_PicklistSnapshot__c
                    WHERE SystemModStamp <= :this.lastExecTS AND Picklist__c in :processedFields];
                System.debug('upsertPicklists: old #Snapshots fetched ' + oldSnapshots.size());
                if (oldSnapshots.size() > 0) {
                    System.debug('upsertPicklists: deleting old Snapshots');
                    delete oldSnapshots;
                }
                else {
                    System.debug('upsertPicklists: no old Snapshot to delete');
                }
            }

            if (this.picklistList.isEmpty()) {
                System.debug('upsertPicklists: END / requeueing for final purge');
                if ((!Test.isRunningTest()) && (this.lastExecTS != null)) {
                    System.enqueueJob(new SYS_PicklistSnapshot_QUE(this.lastExecTS));
                }
            }
            else {
                System.debug('upsertPicklists: END / requeueing for #picklist ' + this.picklistList.size());
                if (!Test.isRunningTest()) {
                    System.enqueueJob(new SYS_PicklistSnapshot_QUE(this.picklistList,this.lastExecTS));
                }
            }
        }

        private void purgeOldPicklists() {
            System.debug('purgeOldPicklists: START');

            List<SYS_PicklistSnapshot__c> obsoleteSnapshots = [
                SELECT Id FROM SYS_PicklistSnapshot__c
                WHERE SystemModStamp <= :this.lastExecTS
                LIMIT :MAX_DELETE_ROWS];
            System.debug('purgeOldPicklists: obsolete #Snapshots fetched ' + obsoleteSnapshots.size());
            if (obsoleteSnapshots.size() > 0) {
                System.debug('purgeOldPicklists: deleting old Snapshots');
                delete obsoleteSnapshots;
            }
            else {
                System.debug('purgeOldPicklists: no Snapshot to delete');
            }

            if (obsoleteSnapshots.size() < MAX_DELETE_ROWS) {
                System.debug('upsertPicklists: END / all obsolete snapshots deleted');
            }
            else {
                System.debug('upsertPicklists: END / requeueing for more purge ');
                if (!Test.isRunningTest()) {
                    System.enqueueJob(new SYS_PicklistSnapshot_QUE(this.lastExecTS));
                }
            }
        }
    }
}
