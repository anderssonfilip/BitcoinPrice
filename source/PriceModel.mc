using Toybox.Communications as Comm;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gre;
using Toybox.System as Sys;


class BitcoinPrice
{
	var lastPrice = 0.0;
	var time = "";  // time in UTC for lastPrice as string, e.g. Mar 30, 2015 17:20:00 UTC

	var history = null;
}


class PriceModel
{
	var bcp = null;  // type BitcoinPrice
	
	hidden var baseURL = "http://api.coindesk.com/v1/bpi/";
	hidden var historicalDays = 5;
	hidden var notify;

  	function initialize(handler)
    {
        notify = handler;
		 
		// Comment when using simulator
		var settings = Sys.getDeviceSettings();
		// documented: phoneConnected is missing in vivoactive FW 2.30
		//if(settings has :phoneConnected and !settings.phoneConnected){ notify.invoke("Phone\nnot\nconnected"); return; }
					
		if (Toybox has :Communications) 
		{
			// get last price
			Comm.makeJsonRequest(baseURL + "currentprice/USD.json",
		         				 {}, 
		         				 {}, 
		         				 method(:onReceivePrice));
			
			// get historical price
			var t = Time.now().add(new Time.Duration(-Sys.getClockTime().timeZoneOffset));
			var start = Gre.info(t.add(new Time.Duration(Gre.SECONDS_PER_DAY * -1 * historicalDays)), Gre.FORMAT_SHORT);			 
			var end = Gre.info(t, Gre.FORMAT_SHORT);
						   	   
		    Comm.makeJsonRequest(baseURL + "historical/close.json",
		         				 {	
		         				 	"index" => "USD", 
		         				 	"start" => start.year + "-" + start.month.format("%.2d") + "-" + start.day.format("%.2d"), 
		         				 	"end"=> end.year + "-" + end.month.format("%.2d") + "-" + end.day.format("%.2d")
		         				 }, 
		         				 {}, 
		         				 method(:onReceiveHistory));
      	}
      	else
      	{
      		notify.invoke("Communication\nnot\npossible");
      	}     				 
    }

	function onReceivePrice(responseCode, data)
    {
        if(responseCode == 200)
        {
        	if(bcp == null)
        	{
            	bcp = new BitcoinPrice();
			}
            
            bcp.lastPrice = data["bpi"]["USD"]["rate"].toFloat();
            bcp.time = data["time"]["updated"];
            
            if(bcp.history == null){ return; } // wait for historic data in other callback
            
            notify.invoke(bcp);
        }
        else 
        {
        	handleError(responseCode, data);
        }
    }
	
  	function onReceiveHistory(responseCode, data)
    {
        if(responseCode == 200)
        {
        	if(bcp == null)
        	{
            	bcp = new BitcoinPrice();
           	}
      
            bcp.history = data["bpi"].values();
                        
            if(bcp.lastPrice == 0.0){ return; } // wait for last price in other callback
            	
            notify.invoke(bcp);
        }
        else 
        {
        	handleError(responseCode, data);
        }
    }
    
    function handleError(responseCode, data)
    {
    	if(responseConde == 408) // Request Timeout
		{
			notify.invoke("Data request\ntimed out");
		}
        else
        {
            notify.invoke("Data request\nfailed\nError: " + responseCode.toString());
        }
    }
}