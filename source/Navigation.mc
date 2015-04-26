using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

class Navigation extends Ui.BehaviorDelegate
{
	hidden var mModel;
	
	hidden var currencies = new [4];
	hidden var i = 0;

  	function initialize(priceModel)
    {
    	currencies[0] = "USD";
    	currencies[1] = "CNY";
    
    	mModel = priceModel;
    }

	//! When a next page behavior occurs, onNextPage() is called.
 	//! @return [Boolean] true if handled, false otherwise
	function onNextPage()
   	{
   		// SHOULD THIS BE MOVED to onNextMode???
	   	
   	}
   	
   	//! When a previous page behavior occurs, onPreviousPage() is called.
	//! @return [Boolean] true if handled, false otherwise
	function onPreviousPage()
	{
	   // SHOULD THIS BE MOVED to onPreviousMode???

	}
	   
	//! When a menu behavior occurs, onMenu() is called.
	//! @return [Boolean] true if handled, false otherwise
	function onMenu()
	{
	   
	}
	   
	//! When a back behavior occurs, onBack() is called.
	//! @return [Boolean] true if handled, false otherwise
	function onBack()
	{
	   
	}
	
	//! When a next mode behavior occurs, onNextMode() is called.
	//! @return [Boolean] true if handled, false otherwise
	function onNextMode()
	{
	   	// Callback not working in SIMULATOR, move to onNextMode for testing
	   	
	    i++;
	   	if(i == currencies.size())
	   	{
	   		i = 0;
	   	}
	   	mModel.makePriceRequests(currencies[i]);		
	}
	
	//! When a previous mode behavior occurs, onPreviousMode() is called.
	//! @return [Boolean] true if handled, false otherwise
	function onPreviousMode()
	{
		// Callback not working in SIMULATOR, move to onPreviousMode for testing
	
	   i--;
	   if(i < 0)
	   {
	   		i = currencies.size()-1;
	   }
	   mModel.makePriceRequests(currencies[i]);
	}  
}