/***
* @description      This class enables to take snapshots of SObject available
*                   on an Org (standard, custom, custom settings, managed package...-
*                   and store them in custom object records, providing an easier ability
*                   for analysis. 
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

public without sharing class SYS_ObjectSnapshot_SCH  implements Schedulable {

    /***
    * @description SObject partially processed because of technical accessibility issue
    ***/
    static final private Set<String> SPECIAL_OBJECTS = new Set<String>{
        'SalesforceContract','SalesforceContractFeed',
        'SalesforceInvoice','SalesforceInvoiceFeed',
        'SalesforceQuote','SalesforceQuoteFeed'};
    

    /***
    * @description  Entry method for schedulable trigger.
    *               It parses the current Schema description and registers 
    *               all SObjects found in the SYS_ObjectSnapshot__c custom object.
    *               There is no historisation, the new snapshot replacing the
    *               previous one.
    * @param        context     Schedulable context (if any).
    * @Exception    none
    ***/
    public static void execute(SchedulableContext context) {
        System.debug('execute: START SYS_ObjectSnapshot_SCH');

        DateTime startTS = DateTime.now();

        // Step #1 - Parsing Schema
        System.debug('execute: extracting Object Definitions');
        List<SYS_ObjectSnapshot__c> snapshotList = new List<SYS_ObjectSnapshot__c>();

        for(Schema.SObjectType iter : Schema.getGlobalDescribe().Values()){
            Schema.DescribeSObjectResult iterDesc = iter.getDescribe();
            String iterName = iterDesc.getName();
            System.debug(LoggingLevel.FINE,'execute: processing object ' + iterName);

            String iterType = (iterDesc.isCustomSetting() ? 'Custom Setting' :
                                (iterDesc.isCustom() ? 
                                    (iterName.countMatches('__') > 1 ? 'Managed Package' : null) :
                                    'Standard Object'));
            if (String.isBlank(iterType)) {
                switch on iterName.substringAfterLast('_') {
                    when 'c'    { iterType = 'Custom Object';}
                    when 'e'    { iterType = 'Custom Event';}
                    when 'mdt'  { iterType = 'Custom Metadata';}
                    when 'ka'   { iterType = 'Standard Object';}
                    when 'kav'  { iterType = 'Standard Object';}
                    when else   { iterType = 'Unknown';}
                }
            }
            else if (iterType == 'Standard Object') {
                switch on iterName.substringAfterLast('_') {
                    when 'ChangeEvent'  { iterType = 'CDC Event';}
                    when 'Share'        { iterType = 'Sharing';}
                    when 'Feed'         { iterType = 'Feed';}
                    when 'History'      { iterType = 'History';}
                    when else {
                        if (iterName.endsWith('ChangeEvent'))   {iterType = 'CDC Event';}
                        else if (iterName.endsWith('Share'))    {iterType = 'Sharing';}
                        else if (iterName.endsWith('Feed'))     {iterType = 'Feed';}
                        else if (iterName.endsWith('History'))  {iterType = 'History';}
                    }
                }
            }
            System.debug(LoggingLevel.FINER,'execute: object type determined ' + iterType);

            if (SPECIAL_OBJECTS.contains(iterName)) {
                system.debug(LoggingLevel.FINER,'execute: Processing special Object ' + iterName);
                snapshotList.add(new SYS_ObjectSnapshot__c(
                    Name = iterName,
                    UniqueID__c = iterName,
                    Type__c = iterType,
                    isCustom__c = false,
                    isCustomSet<ting__c = false,
                    Label__c = iterName,
                    rtCount__c = 0
                ));   
            }
            else {
                System.debug(LoggingLevel.FINER,'execute: registering ' + iterName);
                snapshotList.add(new SYS_ObjectSnapshot__c(
                    Name = iterName,
                    UniqueID__c = iterName,
                    Type__c = iterType,
                    isCustom__c = iterDesc.isCustom(),
                    isCustomSetting__c = iterDesc.isCustomSetting(),
                    keyPrefix__c = iterDesc.getKeyPrefix(),
                    Label__c = iterDesc.getLabel(),
                    rtCount__c = iterDesc.getRecordTypeInfos().size()
                ));
            }
        }
        System.debug('execute: #Object Definitions extracted ' + snapshotList.size());

        // Step #2 - Upserting bject Definitions
        upsert snapshotList UniqueID__c;
        System.debug('execute: Object Definitions upserted');

        // Step #3 - Deleting Old Object Definitions
        List<SYS_ObjectSnapshot__c> snapshots2purge = [ SELECT Id
                                                        FROM SYS_ObjectSnapshot__c
                                                        WHERE SystemModStamp <= :startTS ];
        system.debug('execute: #Obsolete Definitions fetched ' + snapshots2purge.size());

        if (!snapshots2purge?.isEmpty()) {
            delete snapshots2purge;
            System.debug('execute: Obsolete Definitions deleted');
        }

        System.debug('execute: END SYS_ObjectSnapshot_SCH');
    }
}
