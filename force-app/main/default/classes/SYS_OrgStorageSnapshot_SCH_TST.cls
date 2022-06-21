/***
* @description  Test class of the SYS_OrgStorageSnapshot_SCH class.
*               Only code coverage objective for now (no real functional test).
* @author       P-E GROS
* @date         June 2022
* @see          SYS_OrgStorageSnapshot_SCH
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
public class SYS_OrgStorageSnapshot_SCH_TST {

    /***
    * @description Initializes the test context.
    ***/
    @testSetup
    public static void testSetup() {
        System.debug('testSetup: START');

        SYS_PicklistSnapshot_SCH_TST.testSetup();
        System.debug('testSetup: common testSetup done');

        System.debug('testSetup: END');
    }

    /***
    * @description Test of the main SYS_OrgLimitSnapshot_SCH execute logic.
    ***/
    static testmethod void testExecute() {

        StaticResource testResource =   [   SELECT Body,Name FROM StaticResource 
                                            WHERE Name = 'SYS_OrgStorageSnapshot_TST' LIMIT 1];
        System.debug('testExecute: testResource fetched ' + testResource);
        System.debug('testExecute: testResource Name ' + testResource.Name);
        //System.debug('testSetup: testResource Body ' + testResource.Body.toString());
        //Blob testContent = base64Decode(testResource.Body);
        SYS_OrgStorageSnapshot_SCH.TEST_PAGE_CONTENT = testResource.Body.toString();
        System.debug('testExecute: testContent init ' + SYS_OrgStorageSnapshot_SCH.TEST_PAGE_CONTENT);

        SYS_OrgStorageSnapshot_SCH.execute(null);

        // second run to test purge !
        SYS_OrgStorageSnapshot_SCH.SETTING.PurgeAfterDays__c = 1;
        SYS_OrgStorageSnapshot_SCH.execute(null);
    }
}