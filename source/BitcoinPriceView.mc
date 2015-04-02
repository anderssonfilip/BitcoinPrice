using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.Math as Math;
using Toybox.System as Sys;
using Toybox.Time as Time;

class BitcoinPriceView extends Ui.View {

   	hidden var mDelta = null;
   	hidden var mPrice = 0.0;
    
    hidden var isHistoricTrendPositive = true;
    hidden var isDailyTrendPositive = true;
    
    hidden var graphHeight = 10;  // height in pixels
        
    //! Load your resources here
    function onLayout(dc) {
        //setLayout(Rez.Layouts.MainLayout(dc));

        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
        
    }

    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) { 
    
        dc.clear();

		if(mDelta != null)
		{
			if(isDailyTrendPositive)
			{
				dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK); 
			}
			else
			{
				dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK); 
			}
    		dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_LARGE, "$ " + Lang.format("$1$", [mPrice.format("%.2f")]), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    	
			var xs = new [6];
			xs[0] = -50;
			xs[1] = -30;
			xs[2] = -10;
			xs[3] = 10;
			xs[4] = 30;
			xs[5] = 50;
			
			dc.setPenWidth(4);
			if(isHistoricTrendPositive)
			{
				dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK); 
			}
			else
			{
				dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK); 
			}
			var xC = dc.getWidth()/2;
			var yC = dc.getHeight()/2 + 40;
			var y = yC - mDelta[0];
			dc.drawLine(xC + xs[0], yC, xC + xs[1], y);
			for(var i = 1 ; i < mDelta.size(); i++)
			{
				dc.drawLine(xC + xs[i], y, xC + xs[i+1], y - mDelta[i]);
				y = y - mDelta[i];
			}
    	}
    	else
    	{
        	dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_LARGE, "Bitcoin\nWaiting for data", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    	}
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    }
    
    
    function onPrice(bcp)
    {        
        if (bcp instanceof BitcoinPrice)
        {
        	mPrice = bcp.lastPrice;
        
			var max = 0.0;
			var delta = new [bcp.history.size()];
			var i;
			for(i = 0;i < bcp.history.size() - 1 ; i++)
			{
				delta[i] = bcp.history[i+1] - bcp.history[i];

				if(Math.pow(delta[i], 2) > max)
				{
					max = delta[i].abs();
				}
			}
			delta[i] = bcp.lastPrice - bcp.history[bcp.history.size()-1];

			var totalPnl = 0.0;
			for(i = 0 ; i < delta.size() ; i++)  // normalize returns
			{
				totalPnl = totalPnl + delta[i];
				delta[i] = (delta[i] / max) * graphHeight;
			}
			isDailyTrendPositive = delta[delta.size()-1] >= 0.0;
			isHistoricTrendPositive = totalPnl >= 0.0;
			
			mDelta = delta;
			
        }
        else if (bcp instanceof Lang.String)
        {
            Sys.println(bcp);
        }
        Ui.requestUpdate();
    }

}