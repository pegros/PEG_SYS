/***
* @description  Test class of the SYS_PicklistSnapshot_SCH class.
*               Only code coverage objective for now (no real functional test).
* @author       P-E GROS
* @date         June 2022
* @see          SYS_PicklistSnapshot_SCH
* @see PEG_SYS package (https://github.com/pegros/PEG_SYS)
*
* Legal Notice
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

@istest
public class SYS_PicklistSnapshot_SCH_TST {

    /***
    * @description Initializes the test context.
    ***/
    @testSetup
    public static void testSetup() {
        System.debug('testSetup: START');

        String currentUserId = UserInfo.getUserId();
        System.debug('testSetup: currentUserId fetched ' + currentUserId);

        Map<ID,PermissionSet> sysPSets = new Map<ID,PermissionSet>([SELECT Id, Name FROM PermissionSet WHERE Name = 'SYS_UseScheduleTools']);
        System.debug('testSetup: SYS_UseScheduleTools fetched ' + sysPSets);

        List<PermissionSetAssignment> currentAssignments = [    select PermissionSetId from PermissionSetAssignment 
                                                                where AssigneeId = :currentUserId and PermissionSetId in :sysPSets.keySet()];
        System.debug('testSetup: currentAssignments fetched ' + currentAssignments);
        for (PermissionSetAssignment iter : currentAssignments) {
            System.debug('testSetup: removing PermissionSet ' + iter.PermissionSetId);
            sysPSets.remove(iter.PermissionSetId);
        }
        System.debug('testSetup: sfpegPSets revised ' + sysPSets);

        List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();
        for (PermissionSet iter : sysPSets.values()) {
            System.debug('testSetup: sfpegPSets processing PSet ' + iter);
            newAssignments.add(new PermissionSetAssignment(AssigneeId = currentUserId, PermissionSetId = iter.Id));
        }
        System.debug('testSetup: newAssignments init ' + newAssignments);

        if (!newAssignments.isEmpty()) {
            insert newAssignments;
            System.debug('testSetup: newAssignments inserted ' + newAssignments);
        }

        System.debug('testSetup: END');
    }

    /***
    * @description Test of the main SYS_PicklistSnapshot_SCH execute logic.
    ***/
    static testmethod void testExecute() {
        System.debug('testFinalPurge: START');
        SYS_PicklistSnapshot_SCH.execute(null);

        // second run to check lastExecTS !
        System.debug('testFinalPurge: 2nd run');
        insert new SYS_PicklistSnapshot__c(Name='TEST');
        SYS_PicklistSnapshot_SCH.execute(null);
        System.debug('testFinalPurge: END');
    }
    
    /***
    * @description Test of the final purge process of the SYS_PicklistSnapshot_QUE execute logic.
    ***/
    static testmethod void testFinalPurge() {
        System.debug('testFinalPurge: START');
        SYS_PicklistSnapshot_SCH.SYS_PicklistSnapshot_QUE finalQueue = new SYS_PicklistSnapshot_SCH.SYS_PicklistSnapshot_QUE(System.now());
        finalQueue.execute(null);
        System.debug('testFinalPurge: END');
    }

    /***
    * @description Test of the SYS_PicklistSnapshot_SCH checkPicklists() utility method.
    ***/
    static testmethod void testControl() {

        List<SYS_PicklistLabel__mdt> picklistList = new List<SYS_PicklistLabel__mdt>();
        try {
            picklistList.add(new SYS_PicklistLabel__mdt(MasterLabel = 'DUMMY_SYS'));
            SYS_PicklistSnapshot_SCH.checkPicklists(picklistList);
            System.debug(LoggingLevel.ERROR,'Bad format not detected');
            System.assert(false);
        }
        catch (Exception e) {
            System.debug('Bad format properly detected');
            System.assert(true);
            picklistList.remove(0);
        }

        try {
            picklistList.add(new SYS_PicklistLabel__mdt(MasterLabel = 'SYS_DUMMY.DUMMY'));
            SYS_PicklistSnapshot_SCH.checkPicklists(picklistList);
            System.debug(LoggingLevel.ERROR,'Bad Object Name not detected');
            System.assert(false);
        }
        catch (Exception e) {
            System.debug('Bad Object Name properly detected');
            System.assert(true);
            picklistList.remove(0);
        }

        try {
            picklistList.add(new SYS_PicklistLabel__mdt(MasterLabel = 'Account.DUMMY'));
            SYS_PicklistSnapshot_SCH.checkPicklists(picklistList);
            System.debug(LoggingLevel.ERROR,'Bad Field Name not detected');
            System.assert(false);
        }
        catch (Exception e) {
            System.debug('Bad Field Name properly detected');
            System.assert(true);
            picklistList.remove(0);
        }

        try {
            picklistList.add(new SYS_PicklistLabel__mdt(MasterLabel = 'Account.Name'));
            SYS_PicklistSnapshot_SCH.checkPicklists(picklistList);
            System.debug(LoggingLevel.ERROR,'Non Picklist field not detected');
            System.assert(false);
        }
        catch (Exception e) {
            System.debug('Non Picklist field properly detected');
            System.assert(true);
            picklistList.remove(0);
        }
    }
}