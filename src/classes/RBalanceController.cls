public class RBalanceController {
    private Decimal sumBalance=0;
    public Decimal getSumBalance(){
        return this.sumBalance;
    }
    public List<BalanceDetails> getBalanceDetails(){
        List<BalanceDetails> balanceDetailsRet = new List<BalanceDetails>();
        for(AccountableCode__c accCode:[SELECT Name,Description__c,(SELECT ID,Balance__c FROM Balance__r)FROM AccountableCode__c ORDER BY Name]){
            BalanceDetails balance = new BalanceDetails();
            balance.accountableCode = accCode.Name;
            balance.accountableName = accCode.Description__c;
            balance.balance = 0;
            for(Balance__c bal:accCode.Balance__r){
                balance.balance += bal.Balance__c;
                sumBalance+=bal.Balance__c;
            }
            if(balance.balance!=0){
                balanceDetailsRet.add(balance);
            }
        }
        return balanceDetailsRet;
    } 
    public class BalanceDetails{
        public String accountableCode {get; set;}
        public String accountableName {get; set;}
        public Decimal balance {get; set;}
        public String getUrl(){
            if(RRequest.deviceDetection()){
                return URL.getSalesforceBaseUrl().toExternalForm() + '/apex/RBalanceDetailsM?accCode=' + accountableCode;            
            }
            return URL.getSalesforceBaseUrl().toExternalForm() + '/apex/RBalanceDetails?accCode=' + accountableCode;            
        }
    }
}