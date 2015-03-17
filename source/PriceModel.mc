using Toybox.Communications as Comm;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gre;
using Toybox.System as Sys;

class BitcoinPrice
{
	var value;
	var time;
	var history;
}

class PriceModel
{
	hidden var notify;

  	function initialize(handler)
    {
        notify = handler;
	
		var today = Time.now();
		Sys.println(today.value());
		var start = Gre.info(today.add(new Time.Duration(Gre.SECONDS_PER_DAY * -5)), Gre.FORMAT_SHORT);
		var end = Gre.info(today, Gre.FORMAT_SHORT);
		
		// get current price
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

	var bcp = null;

	function onReceivePrice(responseCode, data)
    {
        if(responseCode == 200)
        {
        	if(bcp == null)
        	{
            	var bcp = new BitcoinPrice();
			}
            
            Sys.println(data["bpi"]["USD"]["rate"]);
            Sys.println(data["time"]["updated"]);
            
            bcp.price = data["bpi"]["USD"]["rate"];
            //bcp.time = data["time"]["updated"];
            
            if(bcp.history)
            {
            	notify.invoke(bcp);
            }
        }
        else
        {
            notify.invoke("Failed to load\nError: " + responseCode.toString());
        }
    }
	
  	function onReceiveHistory(responseCode, data)
    {
    return;
        if(responseCode == 200)
        {
        	if(bcp == null)
        	{
            	var bcp = new BitcoinPrice();
           	}
      
            bcp.history = data["bpi"];
            
            if(bcp.value)
            {
            	notify.invoke(bcp);
           	}
        }
        else
        {
            notify.invoke("Failed to load\nError: " + responseCode.toString());
        }
    }
}