public class REntriesController {
    public List<EntryHeader> getEntries(){
        List<EntryHeader> entriesRet= new List<EntryHeader>();        
        List<Accounting_Entry__c> entries = [SELECT Name,Entry_Text__c,Transaction__r.Description__c,
                                             Value_Date__c,CreatedBy.Name FROM Accounting_Entry__c
                                             WHERE State__c='Posted' ORDER by Name DESC];
        for(Accounting_Entry__c entry:entries){
            EntryHeader eh= new EntryHeader();
            eh.transactionName=entry.Transaction__r.Description__c;
            eh.valueDate=entry.Value_Date__c.format();
            eh.entryCode=entry.Name;
            eh.createdBy=entry.CreatedBy.Name;
            entriesRet.add(eh);
        }        
        return entriesRet;
    }
    public class EntryHeader{
        public String transactionName{get; set;}
        public String valueDate{get; set;}
        public String entryCode{get; set;}
        public String createdBy{get; set;}
        public String getUrl(){
            return URL.getSalesforceBaseUrl().toExternalForm() + '/apex/REntryDetails?entryCode=' + 
                entryCode;
        }
    }    
}