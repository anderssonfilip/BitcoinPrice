using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.Math as Math;
using Toybox.System as Sys;

class BitcoinPriceView extends Ui.View {

	hidden var commError = null; // place holder for notification of missing Communications module
   	hidden var mDelta = null;
   	hidden var mPrice = 0.0;
    
    hidden var isHistoricTrendPositive = true;
    hidden var isDailyTrendPositive = true;
    
    hidden var graphHeight = 10;  // height in pixels
	hidden var graphWidth = 100;  // width in pixels
        
    //! Load your resources here
    function onLayout(dc) 
    {
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
    }

    //! Restore the state of the app and prepare the view to be shown
    function onShow() 
    {
    
    }
    
    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() 
    {
    
    }

    //! Update the view
    function onUpdate(dc) { 
    
    	if(commError != null)
    	{
    		dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_LARGE, commError, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    		return;
    	}
    
        dc.clear();

		if(mDelta != null)
		{
			var foreground = null;
			if(isDailyTrendPositive)
			{
				foreground = Graphics.COLOR_GREEN;
			}
			else
			{
				foreground = Graphics.COLOR_RED;
			}
			dc.setColor(foreground, Graphics.COLOR_TRANSPARENT);
			
			var yOffset = dc.getFontHeight(Graphics.FONT_LARGE) + dc.getFontHeight(Graphics.FONT_TINY);
			dc.drawText(dc.getWidth()/2, dc.getHeight()/2 - yOffset, Graphics.FONT_TINY, "Last price", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    		dc.drawText(dc.getWidth()/2, dc.getHeight()/2 - graphHeight*2, Graphics.FONT_LARGE, "$ " + Lang.format("$1$", [mPrice.format("%.2f")]), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    					
			dc.setPenWidth(3);
			
			if(isHistoricTrendPositive)
			{
				foreground = Graphics.COLOR_GREEN;
			}
			else
			{
				foreground = Graphics.COLOR_RED;
			}
			dc.setColor(foreground, Graphics.COLOR_TRANSPARENT);
			
			var xC = dc.getWidth()/2;
			var yC = dc.getHeight()/2 + graphHeight*2;
			
			var xStep = graphWidth / mDelta.size();  // horizontal size of each line segment
			var xs = new [mDelta.size()+1];			 // horizontal start/end point for line segments
			for(var i = 0 ; i < xs.size() ; i++)
			{
				xs[i] = xC + (-0.5*graphWidth + xStep*i);
			}
			
			var y = yC - mDelta[0];
			dc.drawLine(xs[0], yC, xs[1], y);
			var yBottom = y;
			for(var i = 1 ; i < mDelta.size(); i++)
			{
				dc.drawLine(xs[i], y, xs[i+1], y - mDelta[i] * graphHeight);
				y = y - mDelta[i] * graphHeight;
				if(y > yBottom)
				{
					yBottom = y;
				}
			}
			dc.drawText(xC, yBottom + graphHeight, Graphics.FONT_TINY, mDelta.size() + " days", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    	}
    	else
    	{
        	dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_LARGE, "Bitcoin\nWaiting for data", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    	}
    }
    
    //! Called by PriceModel when data is received by JSON request or request returned error.
	//! Processes the data and prepares for a view update
    function onPrice(bcp)
    {        
        if (bcp instanceof BitcoinPrice)
        {
        	mPrice = bcp.lastPrice;
        
			var max = 0.0;
			var delta = new [bcp.history.size()];
			var i;
			for(i = 0;i < bcp.history.size() - 1 ; i++)  // convert prices to returns
			{
				delta[i] = bcp.history[i+1] - bcp.history[i];

				if(delta[i].abs() > max)
				{
					max = delta[i].abs();
				}
			}
			
			// include last price in returns array
			delta[i] = bcp.lastPrice - bcp.history[bcp.history.size()-1];
			if(delta[i].abs() > max)
			{
				max = delta[i].abs();
			}

			var totalPnl = 0.0;
			for(i = 0 ; i < delta.size() ; i++)  // normalize returns
			{
				delta[i] = delta[i] / max;
				totalPnl = totalPnl + delta[i];
			}
			isDailyTrendPositive = delta[delta.size()-1] >= 0.0;
			isHistoricTrendPositive = totalPnl >= 0.0;
			
			mDelta = delta;
        }
        else if (bcp instanceof Lang.String)
        {
        	commError = bcp;	 
       	}
        Ui.requestUpdate();
    }

}