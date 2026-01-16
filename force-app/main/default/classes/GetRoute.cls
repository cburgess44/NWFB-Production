public with sharing class GetRoute {

    public static String startpoint{get{
        return ApexPages.currentPage().getParameters().get('startpoint');
    } set;}
    public static String endpoint{get{
        return ApexPages.currentPage().getParameters().get('endpoint');
    } set;}
    public static String waypoints{get{
        return ApexPages.currentPage().getParameters().get('waypoints');
    } set;}
    public static Boolean optimize{get{
        return Boolean.valueOf(ApexPages.currentPage().getParameters().get('optimize'));
    }set;}

    public void nothing(){}   
}