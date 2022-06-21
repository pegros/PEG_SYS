/***
* @description      This class enables to take break all System Permissions
*                   defined on Permission Sets into individual records providing
*                   system permissions active on each Permission Set / Profile.
*                   Enables more flexible reporting on sensitive system permissions
* @author P-E GROS
* @date   June 2022
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

public with sharing class SYS_PermissionSetDetails_SCH {

    /***
    * @description Entry for schedulable trigger.
    * @param       context        Schedulable context (if any).
    * @Exception   none special.
    ***/

    /*
    public static void execute(SchedulableContext context) {
        System.debug('execute: START SYS_PermissionSetDetails_SCH');

        List<PermissionSet> psets = [select Id from ]
        Set<String> limits2bypass = new Set<String>();
        if (String.isNotBlank(SETTING.BypassedLimits__c)) {
            System.debug('execute: registering limits to bypass ' + SETTING.BypassedLimits__c);
            limits2bypass = new Set<String>(SETTING.BypassedLimits__c.split(','));
            System.debug('execute: bypassed limits registered ' + limits2bypass);
        }
        else {
            System.debug('execute: no limit to bypass');
        }

        Map<String,System.OrgLimit> limitMap = OrgLimits.getMap();
        System.debug('execute: Map fetched with size ' + limitMap.size());

        System.debug('execute: END SYS_PermissionSetDetails_SCH');
    }
    */
}
