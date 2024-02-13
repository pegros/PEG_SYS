/***
* @description      This class enables to take snapshots of Org Storage data
*                   (accessible from System Overview page in Setup)
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

public without sharing class SYS_OrgStorageSnapshot_SCH implements Schedulable {

    /***
    * @description Static constants indicating the limit of deleted records
    ***/
    static final public Integer MAX_DELETES = 9000;

    /***
    * @description Custom Setting to configure the schedulable process.
    ***/
    static final public SYS_OrgStorageConfig__c SETTING = SYS_OrgStorageConfig__c.getInstance();

    /***
    * @description Static variable containing Org Storage data for tests.
    ***/
    static public String TEST_PAGE_CONTENT;

    /***
    * @description  Regex patterns to extract OrgStorage data from HTML page content
    ***/
    static final private Pattern PATTERN_SECTION    = Pattern.compile('(?<=Begin ListElement -->)([\\s\\S]*?)(?=<!-- End ListElement)');
    static final private Pattern PATTERN_TITLE      = Pattern.compile('(?<=<h3>)([\\s\\S]*?)(?=<\\/h3>)');    
    static final private Pattern PATTERN_ROW        = Pattern.compile('<tr class=" dataRow.*<\\/tr>');
    static final private Pattern PATTERN_DATA       = Pattern.compile('<th.*>(.*)<\\/th>(.*<td.*>(.*)<\\/td>)?.*<td.*>(.*)<\\/td>.*<td.*>(.*)<\\/td>');
    static final private Pattern PATTERN_LABEL      = Pattern.compile('<span.*>(.*)<\\/span>');
    static final private Pattern PATTERN_LABEL2     = Pattern.compile('<a.*>(.*)<\\/a>');

    /***
    * @description  Record Type IDs for snapshot records
    ***/
    static private final String RT_ID_Global = Schema.SObjectType.SYS_OrgStorageSnapshot__c.getRecordTypeInfosByDeveloperName().get('Global').getRecordTypeId();
    static private final String RT_ID_Detail = Schema.SObjectType.SYS_OrgStorageSnapshot__c.getRecordTypeInfosByDeveloperName().get('Detail').getRecordTypeId();

    /***
    * @description  Entry method for schedulable trigger.
    *               It takes new snapshots of all Storage usage listed in the Setup page
    *               (limiting to the first N most important objects as configured
    *               in the SYS_OrgStorageConfig__c custom setting) and registers them
    *               in the SYS_OrgStorageSnapshot__c custom object (standard CreatedDate 
    *               field corresponding to the snapshot timestamp and Name field 
    *               containing the name of the Object / Storage Type).
    *               If configured in the configuration setting, it then also deletes
    *               all records older than a month.
    * @param        context     Schedulable context (if any).
    * @Exception    none special.
    ***/
    public static void execute(SchedulableContext context) {
        System.debug('execute: START SYS_OrgStorageSnapshot_SCH');
        System.enqueueJob(new SYS_OrgStorageSnapshot_QUE());
        System.debug('execute: END SYS_OrgStorageSnapshot_SCH / queueable enqueued');
    }

    /***
    * @description  Queueable subclass implemented to work around the limitation on
    *               schedulable classes preventing any callout within their execution.
    *               Getting the content of the standard "Org Storage Usage" setup page
    *               indeed represents an implicit callout. 
    ***/
    public class SYS_OrgStorageSnapshot_QUE implements Queueable, Database.AllowsCallouts {
    
        /*public SYS_OrgStorageSnapshot_QUE() {
        }*/
    
        // OLD VERSION NOT SCALABLE ENOUGH
        /*
        public void execute(QueueableContext context) {
            System.debug('execute: START SYS_OrgStorageSnapshot_QUE');

            PageReference pageRef = new PageReference(
                '/setup/org/orgstorageusage.jsp?id='
                + UserInfo.getOrganizationId()
                + '&setupid=CompanyResourceDisk&appLayout=setup&tour=&isdtp=p1');
            String snapshotContent;
            if (Test.isRunningTest()) {
                snapshotContent = TEST_PAGE_CONTENT;
                System.debug('execute: default test snapshot Content used ' + snapshotContent?.length());
            }
            else {
                snapshotContent = (PageRef.getContent()).toString();
                System.debug('execute: snapshot Content fetched with length ' + snapshotContent.length());
            }

            List<SYS_OrgStorageSnapshot__c> newSnapshots = new List<SYS_OrgStorageSnapshot__c>();
            Matcher sectionMatcher = PATTERN_SECTION.matcher(snapshotContent);

            try {
                while (sectionMatcher.find()) {
                    String sectionString = (sectionMatcher.group(1)); 
                    System.debug('execute: section matched ' + sectionString);
                    System.debug('execute: processing section');

                    Matcher titleMatcher = PATTERN_TITLE.matcher(sectionString);
                    String sectionTitle =  'Overall Situation';
                    Boolean isGlobalSituation = true;
                    if (titleMatcher.find()) {
                        System.debug('execute: title matched');
                        System.debug('execute: title match value ' +  titleMatcher.group());
                        sectionTitle = titleMatcher.group(1);
                        isGlobalSituation = false;
                    }
                    System.debug('execute: section title initialized ' + sectionTitle);

                    Matcher rowMatcher = PATTERN_ROW.matcher(sectionString);
                    while (rowMatcher.find()) {
                        String matchString = (rowMatcher.group()); //.replace('&nbsp;',' ');
                        System.debug('execute: processing match string --> ' + matchString);
                        Matcher lineMatcher = PATTERN_DATA.matcher(matchString);
                        if (lineMatcher.find()) {
                            //System.debug('execute: th --> ' + lineMatcher.group(1));
                            System.debug('execute: line match 1 ' + lineMatcher.group(1));
                            System.debug('execute: line match 2 ' + lineMatcher.group(2));
                            System.debug('execute: line match 3 ' + lineMatcher.group(3));
                            System.debug('execute: line match 4 ' + lineMatcher.group(4));
                            System.debug('execute: line match 5 ' + lineMatcher.group(5));

                            if (isGlobalSituation) {
                                System.debug('execute: adding global snapshot --> ' + lineMatcher.group(1) + ' : ' + lineMatcher.group(3) + ' / ' + lineMatcher.group(4) + ' / ' + lineMatcher.group(5));
                                newSnapshots.add(new SYS_OrgStorageSnapshot__c(
                                    RecordTypeId = RT_ID_Global,
                                    Name = lineMatcher.group(1),
                                    Category__c = sectionTitle,
                                    Limit__c =  extractLong(lineMatcher.group(3)),
                                    Used__c = extractLong(lineMatcher.group(4)),
                                    Ratio__c = extractRatio(lineMatcher.group(5))
                                ));
                            }
                            else {
                                System.debug('execute: reanalysing for detail snapshot');
                                if (String.isBlank(lineMatcher.group(1))) {
                                    System.debug('execute: reanalysing detail data snapshot line');
                                    Matcher labelMatcher = PATTERN_LABEL.matcher(matchString);
                                    if (labelMatcher.find()){
                                        System.debug('execute: adding detail data snapshot --> ' + labelMatcher.group(1) + ' : ' + lineMatcher.group(3) + ' / ' + lineMatcher.group(4) + ' / ' + lineMatcher.group(5));
                                        newSnapshots.add(new SYS_OrgStorageSnapshot__c(
                                            RecordTypeId = RT_ID_Detail,
                                            Name = labelMatcher.group(1),
                                            Category__c = sectionTitle,
                                            //Type__c = (fileDetails.contains(labelMatcher.group(1)) ? TYPE_FILE : (bigObjectDetails.contains(labelMatcher.group(1)) ? TYPE_BIG_OBJECT : TYPE_DATA)),
                                            Count__c = extractLong(lineMatcher.group(3)),
                                            Storage__c = extractLong(lineMatcher.group(4)),
                                            Ratio__c = extractRatio(lineMatcher.group(5))
                                        ));
                                    }
                                    else {
                                        System.debug('execute: reanalysing detail user snapshot line');
                                        Matcher labelMatcher2 = PATTERN_LABEL2.matcher(matchString);
                                        if (labelMatcher2.find()){
                                            System.debug('execute: adding detail user snapshot --> ' + labelMatcher2.group(1) + ' : ' + lineMatcher.group(4) + ' / ' + lineMatcher.group(5));
                                            newSnapshots.add(new SYS_OrgStorageSnapshot__c(
                                                RecordTypeId = RT_ID_Detail,
                                                Name = labelMatcher2.group(1),
                                                Category__c = sectionTitle,
                                                //Type__c = (fileDetails.contains(labelMatcher.group(1)) ? TYPE_FILE : (bigObjectDetails.contains(labelMatcher.group(1)) ? TYPE_BIG_OBJECT : TYPE_DATA)),
                                                //Count__c = extractLong(lineMatcher.group(2)),
                                                Storage__c = extractLong(lineMatcher.group(4)),
                                                Ratio__c = extractRatio(lineMatcher.group(5))
                                            ));
                                        }
                                        else {
                                            System.debug('execute: ignoring line (no label found) ' + matchString);
                                        }                  
                                    }
                                }
                                else {
                                    System.debug('execute: adding detail tech user snapshot --> ' + lineMatcher.group(1) + ' : ' + lineMatcher.group(4) + ' / ' + lineMatcher.group(5));
                                    newSnapshots.add(new SYS_OrgStorageSnapshot__c(
                                        RecordTypeId = RT_ID_Detail,
                                        Name = lineMatcher.group(1),
                                        Category__c = sectionTitle,
                                        //Type__c = (fileDetails.contains(labelMatcher.group(1)) ? TYPE_FILE : (bigObjectDetails.contains(labelMatcher.group(1)) ? TYPE_BIG_OBJECT : TYPE_DATA)),
                                        //Count__c = extractLong(lineMatcher.group(2)),
                                        Storage__c = extractLong(lineMatcher.group(4)),
                                        Ratio__c = extractRatio(lineMatcher.group(5))
                                    ));
                                }
                            }
                        }
                        else {
                            System.debug('execute: ignoring line (no match) ' + matchString);   
                        }
                    }
                    System.debug('execute: all section rows processed');
                }
            }
            catch (Exception e) {
                System.debug(LoggingLevel.ERROR,'execute: parsing failure raised / stopping parsing ' + e);   
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
                List<SYS_OrgStorageSnapshot__c> snapshots2delete =
                    [select Id from SYS_OrgStorageSnapshot__c where CreatedDate < :purgeLimit];
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

            System.debug('execute: END SYS_OrgStorageSnapshot_QUE');
        }
        */

        // NEW VERSION MORE SCALABLE
        public void execute(QueueableContext context) {
            System.debug('execute: START SYS_OrgStorageSnapshot_QUE');

            // Step #1 - Fetching storage data from page
            PageReference pageRef = new PageReference(
                '/setup/org/orgstorageusage.jsp?id='
                + UserInfo.getOrganizationId()
                + '&setupid=CompanyResourceDisk&appLayout=setup&tour=&isdtp=p1');
            String snapshotContent;
            if (Test.isRunningTest()) {
                snapshotContent = TEST_PAGE_CONTENT;
                System.debug('execute: default test snapshot Content used ' + snapshotContent?.length());
            }
            else {
                snapshotContent = (PageRef.getContent()).toString();
                System.debug('execute: snapshot Content fetched with length ' + snapshotContent.length());
            }

            // Step #1 - Extracting Snapshot Data
            List<SYS_OrgStorageSnapshot__c> newSnapshots = new List<SYS_OrgStorageSnapshot__c>();
            Integer index = 0;
            while (index != -1) {
                System.debug('parseNextSection: processing next section from index ' + index);
                index = parseNextSection(snapshotContent,index,newSnapshots);
            }
            System.debug('execute: all sections processed generating #snapshots ' + newSnapshots.size());

            // Step #3 - Registering & purging Snapshots
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
                List<SYS_OrgStorageSnapshot__c> snapshots2delete =
                    [SELECT Id FROM SYS_OrgStorageSnapshot__c WHERE CreatedDate < :purgeLimit LIMIT :MAX_DELETES];
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

            System.debug('execute: END SYS_OrgStorageSnapshot_QUE');
        }

        // Private utility methods
        private Integer parseNextSection(final String snapshotContent,Integer index, List<SYS_OrgStorageSnapshot__c> newSnapshots) {
            System.debug('parseNextSection: START at index ' + index);
            
            // Determining Section limits
            Integer sectionStart = snapshotContent.indexOf('<h3>',index);
            System.debug('parseNextSection: section start found ' + sectionStart);
            if (sectionStart == -1) {
                System.debug('parseNextSection: END / end of content reached ');
                return -1;
            }

            Integer tableStart = snapshotContent.indexOf('<table',sectionStart + 4);
            System.debug('parseNextSection: table start found ' + tableStart);

            Integer sectionEnd = snapshotContent.indexOf('</table>',tableStart + 6) + 8;
            System.debug('parseNextSection: section end found ' + sectionEnd);
            index = sectionEnd + 1;
            System.debug('parseNextSection: index updated ' + index);

            // Initializing Snapshot template
            SYS_OrgStorageSnapshot__c snapshotTemplate = new SYS_OrgStorageSnapshot__c(
                RecordTypeId = RT_ID_Global,
                Category__c = 'Overall Situation'
            );
            String sectionHeader = snapshotContent.substring(sectionStart, tableStart);
            System.debug('parseNextSection: section header determined ' + sectionHeader);
            Matcher titleMatcher = PATTERN_TITLE.matcher(sectionHeader);
            if (titleMatcher.find()) {
                System.debug('parseNextSection: updating default title to ' +  titleMatcher.group());
                snapshotTemplate.RecordTypeId = RT_ID_Detail;
                snapshotTemplate.Category__c = titleMatcher.group(1);
            }
            System.debug('parseNextSection: snapshot template initialized ' + snapshotTemplate);

            // Processing Section rows
            Integer rowIndex = tableStart;
            while (rowIndex != -1) {
                System.debug('parseNextSection: processing next row from index ' + rowIndex);
                rowIndex = parseNextRow(snapshotContent,rowIndex,sectionEnd,newSnapshots,snapshotTemplate);
            }
            System.debug('parseNextSection: END / all rows processed with now #snapshots ' + newSnapshots.size());
            return index;
        }

        private Integer parseNextRow(final String snapshotContent,Integer rowIndex, final Integer maxIndex,
                                    List<SYS_OrgStorageSnapshot__c> newSnapshots, final SYS_OrgStorageSnapshot__c snapshotTemplate) {
            System.debug('parseNextRow: START at index ' + rowIndex);

            // Determining Row limits
            Integer rowStart = snapshotContent.indexOf('<tr',rowIndex);
            System.debug('parseNextRow: row start found ' + rowStart);
            if (rowStart == -1) {
                System.debug('parseNextRow: END / end of content reached ');
                return -1;
            }
            else if (rowStart > maxIndex) {
                System.debug('parseNextRow: END / end of section reached ');
                return -1;
            }

            Integer rowEnd = snapshotContent.indexOf('</tr>',rowStart + 3) + 5;
            System.debug('parseNextRow: row end found ' + rowEnd);
            rowIndex = rowEnd + 1;
            System.debug('parseNextRow: rowIndex updated ' + rowIndex);

            String rowString = snapshotContent.substring(rowStart, rowEnd);
            System.debug('parseNextRow: row data determined ' + rowString);

            Matcher lineMatcher = PATTERN_DATA.matcher(rowString);
            if (lineMatcher.find()) {
                System.debug('parseNextRow: line match 1 ' + lineMatcher.group(1));
                System.debug('parseNextRow: line match 2 ' + lineMatcher.group(2));
                System.debug('parseNextRow: line match 3 ' + lineMatcher.group(3));
                System.debug('parseNextRow: line match 4 ' + lineMatcher.group(4));
                System.debug('parseNextRow: line match 5 ' + lineMatcher.group(5));

                SYS_OrgStorageSnapshot__c newSnap = snapshotTemplate.clone(false, false, false, false);
                if (snapshotTemplate.recordTypeId == RT_ID_Global) {
                    System.debug('parseNextRow: adding global snapshot --> ' + lineMatcher.group(1) + ' : ' + lineMatcher.group(3) + ' / ' + lineMatcher.group(4) + ' / ' + lineMatcher.group(5));
                    newSnap.Name = lineMatcher.group(1);
                    newSnap.Limit__c = extractLong(lineMatcher.group(3));
                    newSnap.Used__c = extractLong(lineMatcher.group(4));
                    newSnap.Ratio__c = extractRatio(lineMatcher.group(5));
                }
                else {
                    System.debug('parseNextRow: reanalysing for detail snapshot');
                    if (String.isBlank(lineMatcher.group(1))) {
                        System.debug('parseNextRow: reanalysing detail data snapshot line');
                        Matcher labelMatcher = PATTERN_LABEL.matcher(rowString);
                        if (labelMatcher.find()) {
                            System.debug('parseNextRow: adding detail data snapshot --> ' + labelMatcher.group(1) + ' : ' + lineMatcher.group(3) + ' / ' + lineMatcher.group(4) + ' / ' + lineMatcher.group(5));
                            newSnap.Name = labelMatcher.group(1);
                            newSnap.Count__c = extractLong(lineMatcher.group(3));
                            newSnap.Storage__c = extractLong(lineMatcher.group(4));
                            newSnap.Ratio__c = extractRatio(lineMatcher.group(5));
                        }
                        else {
                            System.debug('parseNextRow: reanalysing detail user snapshot line');
                            Matcher labelMatcher2 = PATTERN_LABEL2.matcher(rowString);
                            if (labelMatcher2.find()){
                                System.debug('parseNextRow: adding detail user snapshot --> ' + labelMatcher2.group(1) + ' : ' + lineMatcher.group(4) + ' / ' + lineMatcher.group(5));
                                newSnap.Name = labelMatcher2.group(1);
                                newSnap.Storage__c = extractLong(lineMatcher.group(4));
                                newSnap.Ratio__c = extractRatio(lineMatcher.group(5));        
                            }
                            else {
                                System.debug('parseNextRow: ignoring line (no label found) ' + rowString);
                            }                  
                        }
                    }
                    else {
                        System.debug('parseNextRow: adding detail tech user snapshot --> ' + lineMatcher.group(1) + ' : ' + lineMatcher.group(4) + ' / ' + lineMatcher.group(5));
                        newSnap.Name = lineMatcher.group(1);
                        newSnap.Storage__c = extractLong(lineMatcher.group(4));
                        newSnap.Ratio__c = extractRatio(lineMatcher.group(5));
                    }
                }

                newSnapshots.add(newSnap);
                System.debug('parseNextRow: END / new Snapshot registered ' + newSnap);
            }
            else {
                System.debug('parseNextRow: END KO / no data match');
            }
            return rowIndex;
        }

        private Long extractLong(final String valueStr) {
            System.debug(LoggingLevel.FINEST,'extractLong: START with ' + valueStr);
            Double value;
            if (valueStr.contains('&nbsp;')) {
                List<String> valueParts = valueStr.split('&nbsp;');
                System.debug(LoggingLevel.FINEST,'extractLong: valueParts extracted ' + valueParts);
                value = Double.valueOf(valueParts[0].replace(',','.').replace(' ','').replace(' ',''));
                if (valueParts[1] == 'KB') {
                    System.debug(LoggingLevel.FINEST,'extractLong: managing KB');
                    value = value * 1024;
                }
                else if (valueParts[1] == 'MB') {
                    System.debug(LoggingLevel.FINEST,'extractLong: managing MB');
                    value = value * 1024 * 1024;
                }
                else if (valueParts[1] == 'GB') {
                    System.debug(LoggingLevel.FINEST,'extractLong: managing GB');
                    value = value * 1024 * 1024 * 1024;
                }
                else if (valueParts[1] == 'TB') {
                    System.debug(LoggingLevel.FINEST,'extractLong: managing TB');
                    value = value * 1024 * 1024 * 1024 * 1024;
                }
            }
            else {
                System.debug(LoggingLevel.FINEST,'extractLong: baseline conversion ' + valueStr.replace(',','.').replace(' ','').replace(' ','').trim());
                value = Double.valueOf(valueStr.replace(',','.').replace(' ','').replace(' ','').trim());
            }
            System.debug(LoggingLevel.FINEST,'extractLong: END with ' + value.round());
            return value.round();
        }

        private Decimal extractRatio(final String valueStr) {
            System.debug(LoggingLevel.FINEST,'extractRatio: START with ' + valueStr);
            /*String test = valueStr.replace('%','');
            System.debug('extractRatio: % removed ' + test);
            test = test.replace(' ','');
            System.debug('extractRatio: strange space removed ' + test);
            test = test.replace(',','.');
            System.debug('extractRatio: comma replaced by . ' + test);
            test = test.trim();
            System.debug('extractRatio: trim done ' + test);*/

            Decimal value = Decimal.valueof(valueStr.replace('%','').replace(' ','').replace(',','.').trim());
            System.debug(LoggingLevel.FINEST,'extractRatio: END with ' + value.round());
            return value;
        }

    } 
}