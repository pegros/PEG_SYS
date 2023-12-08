/***
* @description  Test class of the SYS_PermissionSnapshot_SCH class.
*               Only code coverage objective for now (no real functional test).
* @author       P-E GROS
* @date         Dec 2023
* @see          SYS_PermissionSnapshot_SCH
* @see PEG_SYS package (https://github.com/pegros/PEG_SYS)
*
* Legal Notice
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

@istest
public class SYS_PermissionSnapshot_SCH_TST {

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
    * @description Test of the main SYS_PermissionSnapshot_SCH execute logic.
    ***/
    static testmethod void testExecute() {
        System.debug('testExecute: START');
        SYS_PermissionSnapshot_SCH.execute(null);

        // second run to check lastExecTS !
        System.debug('testExecute: 2nd run');
        insert new SYS_PermissionSnapshot__c(Name='TEST');
        SYS_PermissionSnapshot_SCH.execute(null);
        System.debug('testExecute: END');
    }

    /***
    * @description Test of the main SYS_PermissionSnapshot_QUE purge logic.
    ***/
    static testmethod void testPurge() {
        System.debug('testPurge: START');
        PermissionSet lastPSet = [SELECT Id FROM PermissionSet order by Id desc LIMIT 1][0];

        // second run to check lastExecTS !
        System.debug('testPurge: 2nd run');
        insert new SYS_PermissionSnapshot__c(Name='TEST');
        SYS_PermissionSnapshot_SCH.SYS_PermissionSnapshot_QUE testQueue = new SYS_PermissionSnapshot_SCH.SYS_PermissionSnapshot_QUE(
            new List<String>{'Id'},System.now(), lastPSet.id);
        testQueue.execute(null);
        System.debug('testPurge: END');
    }
}