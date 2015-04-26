using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.Math as Math;
using Toybox.System as Sys;

class BitcoinPriceView extends Ui.View {

	hidden var commError = null; // place holder for notification of missing Communications module
   	hidden var mPoints = null;   // price points in graph
	hidden var mCurrency;
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

		if(mPoints != null)
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
			
			var graphWidth = dc.getTextWidthInPixels("9999.99", priceFont);
			var xC = dc.getWidth()/2;
			var xStep = graphWidth / mPoints.size();  // horizontal size of each line segment
			var xs = new [mPoints.size()];			 // horizontal start/end point for line segments
			for(var i = 0 ; i < xs.size() ; i++)
			{
				xs[i] = xC + (-0.5*graphWidth + xStep*i);
			}
			
			var top = dc.getHeight()/2 + 0.5 * graphHeight;
    		var bottom = top + graphHeight;
    		
			for(var i = 1 ; i < mPoints.size(); i++)
			{
				dc.drawLine(xs[i-1], bottom - mPoints[i-1], xs[i], bottom - mPoints[i]);
			}
	
			dc.drawText(xC, 
						bottom + dc.getTextDimensions("5 days", textFont)[1]/2 + 2,
						textFont, 
						mPoints.size()-1 + " days", 
						Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

    		drawOpenClosePricesInGraph(dc, 
    								   xs[0],
    								   top,
    								   xs[xs.size()-1], 
    								   bottom);
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

    	dc.drawText(dc.getWidth()/2 - dc.getTextWidthInPixels(lastPriceValue, priceFont)/2 - 5, 
    				y2, 
    				Graphics.FONT_LARGE, 
    				mCurrency, 
    				Graphics.TEXT_JUSTIFY_RIGHT);
    				
    	dc.drawText(dc.getWidth()/2, 
    				y3, 
    				priceFont, 
    				lastPriceValue, 
    				Graphics.TEXT_JUSTIFY_CENTER);
    }
     
    //! Draw high/low price next to graph
    function drawOpenClosePricesInGraph(dc, left, top, right, bottom)
    {
		dc.setPenWidth(1);
		dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);  // overpainting
		
		dc.drawLine(left, top, right, top);	  	
		dc.drawLine(left, bottom, right, bottom);
		
		dc.drawText(right, bottom, Graphics.FONT_XTINY, round(mLow).format("%d"), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
		dc.drawText(right, top, Graphics.FONT_XTINY, round(mHigh).format("%d"), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    
    //! Called by PriceModel when data is received by JSON request or request returned error.
	//! Processes the data and prepares for a view update
    function onPrice(bcp)
    {        
        if (bcp instanceof BitcoinPrice)
        {
        	mHigh = 0.0;
        	mLow = 0.0;
        	
        	if(bcp.currency.equals("USD"))
        	{
        		mCurrency = "$";
        	}
        	else if(bcp.currency.equals("CNY"))
        	{
        		mCurrency = "¥";
        	}
        	
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
			var points = new[bcp.history.size() + 1];
			for(var i = 0 ; i < points.size() - 1 ; i++)  // normalize prices
			{
				points[i] = ((bcp.history[i][1] - mLow)/range) * graphHeight;
			}
			points[bcp.history.size()] = ((bcp.lastPrice - mLow)/range) * graphHeight;
			
			mPoints = points;
			
			isDailyTrendPositive = bcp.lastPrice - bcp.history[bcp.history.size()-1][1] >= 0.0;
			isHistoricTrendPositive = bcp.lastPrice - bcp.history[0][1] >= 0.0;
			
        }
        else if (bcp instanceof Lang.String)
        {
        	commError = bcp;	 
       	}
        Ui.requestUpdate();
    }
    
    //! round a positive Float or Double, return a Long
   	function round(value)
	{
		if(value - value.toLong() >= 0.5)
		{
			return (value+1).toLong();
		}
		else
		{
			return value.toLong();
		}
	}
}