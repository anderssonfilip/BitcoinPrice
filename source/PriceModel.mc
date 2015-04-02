using Toybox.Communications as Comm;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gre;
using Toybox.System as Sys;


var historicalDays = 5;

class BitcoinPrice
{
	var lastPrice = 0.0;
	var time = "";  // time in UTC for lastPrice as string, e.g. Mar 30, 2015 17:20:00 UTC

	var history = null;
}


class PriceModel
{
	var bcp = null;
	
	hidden var notify;

  	function initialize(handler)
    {
        notify = handler;
	
		var utcNow = Time.now();

		var start = Gre.info(utcNow.add(new Time.Duration(Gre.SECONDS_PER_DAY * -1 * historicalDays)), Gre.FORMAT_SHORT);
		var end = Gre.info(utcNow, Gre.FORMAT_SHORT);
		 
		// Comment when using simulator
		var settings = Sys.getDeviceSettings();
		// documented: phoneConnected is missing in vivoactive FW 2.30
		if(settings has :phoneConnected and !settings.phoneConnected){ notify.invoke("Phone\nnot\nconnected"); return; }
				
		if (Toybox has :Communications) 
		{
			// get last price
			Comm.makeJsonRequest("http://api.coindesk.com/v1/bpi/currentprice/USD.json",
		         				 {}, 
		         				 {}, 
		         				 method(:onReceivePrice));
			
			// get historical price
		    Comm.makeJsonRequest("http://api.coindesk.com/v1/bpi/historical/close.json",
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
            
            if(bcp.history != null)
            {
            	notify.invoke(bcp);
            }
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
                        
            if(bcp.lastPrice != 0.0)
            {
            	notify.invoke(bcp);
           	}
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