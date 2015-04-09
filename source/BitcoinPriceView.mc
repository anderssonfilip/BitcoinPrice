using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.Math as Math;
using Toybox.System as Sys;

class BitcoinPriceView extends Ui.View {

	hidden var commError = null; // place holder for notification of missing Communications module
   	hidden var mDelta = null;
   	hidden var mLastPrice = 0.0;
   	hidden var mLastReturn = 0.0;  // total return (%) over last day period, including last price
   	hidden var mHigh = 0.0;
   	hidden var mLow = 0.0;
    
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
			var graphPenWidth = 3;
			
			if(isDailyTrendPositive)
			{
				foreground = Graphics.COLOR_GREEN;
			}
			else
			{
				foreground = Graphics.COLOR_RED;
			}
			dc.setColor(foreground, Graphics.COLOR_TRANSPARENT);
			
			drawLastPrice(dc);
							
			dc.setPenWidth(graphPenWidth);
			
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
			
			var y = yC;
			dc.drawLine(xs[0], yC, xs[1], y);
			var yBottom = y;
			var yTop = y;
			for(var i = 1 ; i < mDelta.size(); i++)
			{
				dc.drawLine(xs[i], y, xs[i+1], y - mDelta[i] * graphHeight);
				y = y - mDelta[i] * graphHeight;
				if(y > yBottom)
				{
					yBottom = y;
				}
				else if(y < yTop)
				{
					yTop = y;
				}
			}
			
			Sys.println("yTop: " + yTop);
			
			dc.drawText(xC, yBottom + graphHeight, Graphics.FONT_TINY, mDelta.size() + " days", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    		
    		drawOpenClosePricesInGraph(dc, 
    								  xs[0], xs[xs.size()-1], 
    								  yBottom + graphPenWidth/2, yTop - graphPenWidth/2, 
    								  mLow,
    								  mHigh);
    	}
    	else
    	{
        	dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_LARGE, "Bitcoin\nWaiting for data", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    	}
    }
    
    //! Draw last price and return since yesterday
    function drawLastPrice(dc)
    {
    	var priceFont = Graphics.FONT_NUMBER_HOT;
    	var textFont = Graphics.FONT_TINY;
    	
    	var lastPriceValue = Lang.format("$1$", [mLastPrice.format("%.2f")]);
    
    	var fstRowY = dc.getHeight()/2 - dc.getTextDimensions("0", priceFont)[1]/2 - dc.getTextDimensions("0", textFont)[1];
    	var sndRowY = dc.getHeight()/2- dc.getTextDimensions("0", priceFont)[1]/2;
		
		dc.drawText(dc.getWidth()/2 - dc.getTextWidthInPixels(lastPriceValue, priceFont)/2 - 10, 
					fstRowY, 
					textFont, 
					"Last price", 
					Graphics.TEXT_JUSTIFY_LEFT);
					
    	dc.drawText(dc.getWidth()/2 + dc.getTextWidthInPixels(lastPriceValue, priceFont)/2,
					fstRowY, 
					textFont, 
					Lang.format("$1$", [(mLastReturn * 100).format("%.2f")]) + "%", 
					Graphics.TEXT_JUSTIFY_RIGHT);
    	

    	dc.drawText(dc.getWidth()/2 - dc.getTextWidthInPixels(lastPriceValue, priceFont)/2, 
    				sndRowY, 
    				Graphics.FONT_LARGE, 
    				"$ ", 
    				Graphics.TEXT_JUSTIFY_RIGHT);
    				
    	dc.drawText(dc.getWidth()/2, 
    				sndRowY, 
    				priceFont, 
    				lastPriceValue, 
    				Graphics.TEXT_JUSTIFY_CENTER);


    }
     
    //! Draw high/low price next to graph
    function drawOpenClosePricesInGraph(dc, xLeft, xRight, yBottom, yTop, open, close)
    {
		dc.setPenWidth(1);
		dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);  // overpainting
		
		dc.drawLine(xLeft, yTop, xRight, yTop);	
		dc.drawLine(xLeft, yBottom, xRight, yBottom);
		
		// TODO: price should be rounded not truncated
		dc.drawText(xRight, yBottom, Graphics.FONT_XTINY, open.format("%d"), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
		dc.drawText(xRight, yTop, Graphics.FONT_XTINY, close.format("%d"), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    
    //! Called by PriceModel when data is received by JSON request or request returned error.
	//! Processes the data and prepares for a view update
    function onPrice(bcp)
    {        
        if (bcp instanceof BitcoinPrice)
        {
        	mLastPrice = bcp.lastPrice;
        	
        	// return since yesterday
        	mLastReturn = (mLastPrice - bcp.history[bcp.history.size()-1])/bcp.history[bcp.history.size()-1];
        
			var max = 0.0;
			var delta = new [bcp.history.size()];
			mHigh = bcp.history[0];
			mLow = bcp.history[0];
			var i;
			for(i = 0;i < bcp.history.size() - 1 ; i++)  // convert prices to returns, find open close
			{
				delta[i] = bcp.history[i+1] - bcp.history[i];

				if(delta[i].abs() > max)
				{
					max = delta[i].abs();
				}
				
				if(bcp.history[i] > mHigh)
				{
					mHigh = bcp.history[i];
				}
				if(bcp.history[i] < mLow)
				{
					mLow = bcp.history[i];
				}
				
			}
			
			// include last price in returns array
			delta[i] = bcp.lastPrice - bcp.history[bcp.history.size()-1];
			if(delta[i].abs() > max)
			{
				max = delta[i].abs();
			}
			if(bcp.lastPrice > mHigh)
			{
				mHigh = bcp.lastPrice;
			}
			if(bcp.lastPrice < mLow)
			{
				mLow = bcp.lastPrice;
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