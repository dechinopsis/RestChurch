public class RBalanceDetailsController {
    private String balanceDescription;
    private String accountableCode;
    private Boolean analyzeByMember;
    private Boolean sentMember;
    private String member =null;
    private String memberName =null;
    private Decimal balanceAmmout;
    public RBalanceDetailsController(){
        String accCode = ApexPages.currentPage().getParameters().get('accCode');
        this.member = ApexPages.currentPage().getParameters().get('member');              
        this.sentMember =(member!=null);
        Member__c currMem=null;
        if(this.sentMember){
            currMem=[SELECT MemberName__c From Member__c WHERE Name =:this.member];
            this.memberName =currMem.MemberName__c;
        }
        this.accountableCode = accCode;
        AccountableCode__c mayor = [SELECT Name,Description__c,Member__c,
                                    (SELECT ID,Balance__c,Member__c FROM Balance__r)
                                    FROM AccountableCode__c WHERE Name =:accCode];
        this.analyzeByMember = mayor.Member__c;
        this.balanceAmmout =0;
        for(Balance__c bal:mayor.Balance__r){
            if(this.analyzeByMember && this.sentMember){
                if(bal.Member__c==currMem.Id){
                    this.balanceAmmout += bal.Balance__c;
                }
            }else{
                this.balanceAmmout += bal.Balance__c;
            }
        }
        this.balanceDescription=mayor.Description__c;        
    }
    public List<MovementDetail> getBalanceDetails(){
        Decimal balance = 0;
        List<MovementDetail> balanceDetailsRet = new List<MovementDetail>();
        List<Accounting_Entry_Details__c> ordinals =null;
        if(this.analyzeByMember && this.sentMember){
            ordinals =[SELECT Accounting_Entry_Parent__r.Value_Date__c,
                       Accounting_Entry_Parent__r.Transaction__r.Description__c,
                       Accounting_Entry_Parent__r.Name,Amount__c,Debt__c
                       FROM Accounting_Entry_Details__c WHERE
                       Accountable_Code__r.Name=:this.accountableCode AND
                       Accounting_Entry_Parent__r.State__c='Posted' AND
                       Member__r.Name=:this.member
                       ORDER BY Accounting_Entry_Parent__r.Name];
        }
        else{
            ordinals =[SELECT Accounting_Entry_Parent__r.Value_Date__c,
                       Accounting_Entry_Parent__r.Transaction__r.Description__c,
                       Accounting_Entry_Parent__r.Name,Amount__c,Debt__c
                       FROM Accounting_Entry_Details__c WHERE
                       Accountable_Code__r.Name=:this.accountableCode AND
                       Accounting_Entry_Parent__r.State__c='Posted'
                       ORDER BY Accounting_Entry_Parent__r.Name];
        }
        for(Accounting_Entry_Details__c ordinal:ordinals){            
            MovementDetail currMove = new MovementDetail();
            currMove.entryCode = ordinal.Accounting_Entry_Parent__r.Name;            
            Date tmp= ordinal.Accounting_Entry_Parent__r.Value_Date__c;
            currMove.valueDate = tmp.format();
            currMove.concept = ordinal.Accounting_Entry_Parent__r.Transaction__r.Description__c;
            if(ordinal.Debt__c){
                currMove.debt = String.valueOf(ordinal.Amount__c);
                currMove.credit = '';
                balance-=ordinal.Amount__c;
            }
            else{
                currMove.credit = String.valueOf(ordinal.Amount__c);
                currMove.debt =  '';
                balance+=ordinal.Amount__c;
            }  
            currMove.balance = balance;
            balanceDetailsRet.add(currMove);
        }
        return balanceDetailsRet;
    } 
    
    public List<MemberDetail> getmemberDetails(){
        List<MemberDetail> memberDetailsRet = new List<MemberDetail>();
        List<Balance__c> balance = [SELECT Balance__c,Member__r.MemberName__c,Member__r.Name FROM Balance__c
         WHERE Member__c!=null and Accountable_Code__r.name=:this.accountableCode];
        for(Balance__c bal:balance){
            MemberDetail actualMember = new MemberDetail();
            actualMember.memberCode = bal.Member__r.Name;
            actualMember.name =bal.Member__r.MemberName__c;
            actualMember.balance =bal.Balance__c;
            actualMember.accountableCode =this.accountableCode;
            memberDetailsRet.add(actualMember);
        }
        return memberDetailsRet;
    } 
    
    public class MemberDetail{
        public String accountableCode{get; set;}
        public String memberCode {get; set;}
        public String name {get; set;}
        public Decimal balance {get; set;}
        public String getUrl(){
            return URL.getSalesforceBaseUrl().toExternalForm() + '/apex/RBalanceDetails?accCode=' + 
                accountableCode+'&member='+memberCode;
        }
    }
    public class MovementDetail{
        public String entryCode {get; set;}
        public String valueDate {get; set;}
        public String concept {get; set;}
        public String debt {get; set;}
        public String credit {get; set;}
        public Decimal balance {get; set;}
        public String getUrl(){
            return URL.getSalesforceBaseUrl().toExternalForm() + '/apex/REntryDetails?entryCode=' + 
                entryCode;
        }
    }
    public Boolean getAnalyzeByMember(){
        return this.analyzeByMember;
    }      
    public String getBalanceDescription(){
        return this.balanceDescription;
    }
    public String getAccountableCode(){
        return this.accountableCode;
    }
    public Decimal getBalanceAmmout(){
        return this.balanceAmmout;
    }
    public Boolean getSentMember(){
        return this.sentMember;
    }
    public String getMemberName(){
        return this.memberName;
    }
}