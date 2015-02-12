public class REntryDetailsController {
    private String transactionName;
    private String valueDate;
    private String text;
    private String entryCode;
    private String createdBy;
    public REntryDetailsController(){
        this.entryCode = ApexPages.currentPage().getParameters().get('entryCode');
        Accounting_Entry__c entry = [SELECT Entry_Text__c,Transaction__r.Description__c,Value_Date__c,
                                     CreatedBy.Name FROM Accounting_Entry__c
                                     WHERE Name =:this.entryCode];
        this.transactionName=entry.Transaction__r.Description__c;
        this.valueDate=entry.Value_Date__c.format();
        this.text=entry.Entry_Text__c;
        this.createdBy = entry.CreatedBy.Name;
    }
    public List<Ordinal>getEntryDetails(){
        List<Ordinal>retOrdinals=new List<Ordinal>();        
        List<Accounting_Entry_Details__c> ordinals=[SELECT Accountable_Code__r.Description__c,Amount__c,
                                                    Debt__c,Member__r.MemberName__c,Ordinal__c 
                                                    FROM Accounting_Entry_Details__c WHERE
                                                    Accounting_Entry_Parent__r.Name=:this.entryCode
                                                    ORDER BY Ordinal__c];
        for(Accounting_Entry_Details__c ordinal:ordinals){
            Ordinal aux = new Ordinal();
            aux.ordinal = ordinal.Ordinal__c;
            aux.accName = ordinal.Accountable_Code__r.Description__c;
            if(ordinal.Member__r.MemberName__c!=null){
                aux.member = ordinal.Member__r.MemberName__c;
            }
            else{
                aux.member = '';
            }
            if(ordinal.Debt__c){
                aux.debt = String.valueOf(ordinal.Amount__c);
                aux.credit = '';
            }
            else{
                aux.credit = String.valueOf(ordinal.Amount__c);
                aux.debt = '';
            }
            retOrdinals.add(aux);
        }
        return retOrdinals;
    }
    public class Ordinal{
        public Decimal ordinal {get; set;}
        public String accName {get; set;}
        public String member {get; set;}
        public String debt {get; set;}
        public String credit {get; set;}
    }
    public String getEntryCode(){
        return this.entryCode;
    }
    public String getTransactionName(){
        return this.transactionName;
    }
    public String getValueDate(){
        return this.valueDate;
    }
    public String getText(){
        return this.text;
    }
    public String getCreatedBy(){
        return this.createdBy;
    }
}