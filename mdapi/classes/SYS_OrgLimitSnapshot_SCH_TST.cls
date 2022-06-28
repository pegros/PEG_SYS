/***
* @description  Test class of the SYS_OrgLimitSnapshot_SCH class.
*               Only code coverage objective for now (no real functional test).
* @author       P-E GROS
* @date         June 2022
* @see          SYS_OrgLimitSnapshot_SCH
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
public class SYS_OrgLimitSnapshot_SCH_TST {

    /***
    * @description Initializes the test context.
    ***/
    @testSetup
    public static void testSetup() {
        System.debug('testSetup: START');
        SYS_PicklistSnapshot_SCH_TST.testSetup();            
        System.debug('testSetup: END');
    }

    /***
    * @description Test of the main SYS_OrgLimitSnapshot_SCH execute logic.
    ***/
    static testmethod void testExecute() {
        SYS_OrgLimitSnapshot_SCH.execute(null);

        // second run to test purge and bypass !
        SYS_OrgLimitSnapshot_SCH.SETTING.PurgeAfterDays__c = 1;
        SYS_OrgLimitSnapshot_SCH.SETTING.BypassedLimits__c = 'TEST,SYS';
        SYS_OrgLimitSnapshot_SCH.execute(null);
    }
}