public class RRequest {
    public static Boolean deviceDetection(){
        String userAgent = ApexPages.currentPage().getHeaders().get('USER-AGENT');
        
        if (userAgent==null || userAgent.length()==0){
            userAgent = ApexPages.currentPage().getHeaders().get('HTTP_X_OPERAMINI_PHONE_UA');
        }
        if (userAgent==null || userAgent.length()==0){
            userAgent = ApexPages.currentPage().getHeaders().get('HTTP_X_SKYFIRE_PHONE');
        }
        if(userAgent==null){
            return false;
        }
        
        String deviceReg = '(?i)(iphone|ipad|ipod|blackberry|android|palm|windows\\s+ce)';
        String desktopReg = '(?i)(windows|linux|os\\s+[x9]|solaris|bsd)';
        String botReg = '(?i)(spider|crawl|slurp|bot)';
        
        Boolean isDevice=false, isDesktop=false, isBot=false;
        
        Matcher match = Pattern.compile(deviceReg).matcher(userAgent);
        if (match.find()){
            isDevice = true;
        } else {
            match = Pattern.compile(desktopReg).matcher(userAgent);
            if (match.find()) isDesktop = true;
            
            match = Pattern.compile(botReg).matcher(userAgent);
            if (match.find()) isBot = true;
        }
        if (!isDevice && (isDesktop || isBot)) return false;
        return true;
    }
}