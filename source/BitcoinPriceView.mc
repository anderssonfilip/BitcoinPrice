using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.Math as Math;
using Toybox.System as Sys;

class BitcoinPriceView extends Ui.View {

	hidden var commError = null; // place holder for notification of missing Communications module
   	hidden var mEdges = null;
   	hidden var mLastPrice = 0.0;
   	hidden var mLastReturn = 0.0;  // total return (%) over last day period, including last price
   	hidden var mHigh = 0.0;
   	hidden var mLow = 0.0;
   	
   	hidden var priceFont = Graphics.FONT_NUMBER_HOT;
    hidden var textFont = Graphics.FONT_TINY;
    
    hidden var isHistoricTrendPositive = true;
    hidden var isDailyTrendPositive = true;
    
    hidden var graphHeight = 30;  // height in pixels
        
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

		if(mEdges != null)
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
			
			var graphWidth = dc.getTextWidthInPixels("999.99", priceFont);
			var xC = dc.getWidth()/2;
			var xStep = graphWidth / mEdges.size();  // horizontal size of each line segment
			var xs = new [mEdges.size()];			 // horizontal start/end point for line segments
			for(var i = 0 ; i < xs.size() ; i++)
			{
				xs[i] = xC + (-0.5*graphWidth + xStep*i);
			}
			
			var top = dc.getHeight()/2 + 0.5 * graphHeight;
    		var bottom = top + graphHeight;
    		
			for(var i = 1 ; i < mEdges.size(); i++)
			{
				dc.drawLine(xs[i-1], bottom - mEdges[i-1], xs[i], bottom - mEdges[i]);
			}
	
			dc.drawText(xC, 
						bottom + dc.getTextDimensions("5 days", textFont)[1]/2 + 2,
						textFont, 
						mEdges.size()-1 + " days", 
						Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

    		drawOpenClosePricesInGraph(dc, 
    								   xs[0],
    								   top,
    								   xs[xs.size()-1], 
    								   bottom, 
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
    	var lastPriceValue = Lang.format("$1$", [mLastPrice.format("%.2f")]);
    	
    	var y1 = Ui.loadResource(Rez.Strings.y1).toNumber();
       	var y2 = Ui.loadResource(Rez.Strings.y2).toNumber();
    	var y3 = dc.getHeight()/2 - dc.getTextDimensions("0", priceFont)[1];
		
		dc.drawText(dc.getWidth()/2 - dc.getTextWidthInPixels(lastPriceValue, priceFont)/2, 
					y1, 
					textFont, 
					"Price", 
					Graphics.TEXT_JUSTIFY_LEFT);
					
    	dc.drawText(dc.getWidth()/2 + dc.getTextWidthInPixels(lastPriceValue, priceFont)/2,
					y1, 
					textFont, 
					Lang.format("$1$", [(mLastReturn * 100).format("%.2f")]) + "%", 
					Graphics.TEXT_JUSTIFY_RIGHT);

    	dc.drawText(dc.getWidth()/2 - dc.getTextWidthInPixels(lastPriceValue, priceFont)/2, 
    				y2, 
    				Graphics.FONT_LARGE, 
    				"$ ", 
    				Graphics.TEXT_JUSTIFY_RIGHT);
    				
    	dc.drawText(dc.getWidth()/2, 
    				y3, 
    				priceFont, 
    				lastPriceValue, 
    				Graphics.TEXT_JUSTIFY_CENTER);
    }
     
    //! Draw high/low price next to graph
    function drawOpenClosePricesInGraph(dc, left, top, right, bottom, open, close)
    {
		dc.setPenWidth(1);
		dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);  // overpainting
		
		dc.drawLine(left, top, right, top);	  	
		dc.drawLine(left, bottom, right, bottom);
		
		// TODO: price should be rounded not truncated
		dc.drawText(right, bottom, Graphics.FONT_XTINY, open.format("%d"), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
		dc.drawText(right, top, Graphics.FONT_XTINY, close.format("%d"), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    
    //! Called by PriceModel when data is received by JSON request or request returned error.
	//! Processes the data and prepares for a view update
    function onPrice(bcp)
    {        
        if (bcp instanceof BitcoinPrice)
        {
        	mLastPrice = bcp.lastPrice;
        	
        	// return since yesterday
        	mLastReturn = (mLastPrice - bcp.history[bcp.history.size()-1][1])/bcp.history[bcp.history.size()-1][1];

			mHigh = bcp.history[0][1];
			mLow = bcp.history[0][1];
			for(var i = 0; i < bcp.history.size() ; i++)
			{				
				if(bcp.history[i][1] > mHigh)
				{
					mHigh = bcp.history[i][1];
				}
				if(bcp.history[i][1] < mLow)
				{
					mLow = bcp.history[i][1];
				}		
			}
						
			if(bcp.lastPrice > mHigh)
			{
				mHigh = bcp.lastPrice;
			}
			else if(bcp.lastPrice < mLow)
			{
				mLow = bcp.lastPrice;
			}
			
			var range = mHigh - mLow;
			var edges = new[bcp.history.size() + 1];
			for(var i = 0 ; i < edges.size() - 1 ; i++)  // normalize returns
			{
				edges[i] = ((bcp.history[i][1] - mLow)/range) * graphHeight;
			}
			edges[bcp.history.size()] = ((bcp.lastPrice - mLow)/range) * graphHeight;
			
			mEdges = edges;
			
			isDailyTrendPositive = bcp.lastPrice - bcp.history[bcp.history.size()-1][1] >= 0.0;
			isHistoricTrendPositive = bcp.history[bcp.history.size()-1][1] - bcp.history[0][1] >= 0.0;
        }
        else if (bcp instanceof Lang.String)
        {
        	commError = bcp;	 
       	}
        Ui.requestUpdate();
    }

}