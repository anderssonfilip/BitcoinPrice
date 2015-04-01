using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.Math as Math;
using Toybox.System as Sys;
using Toybox.Time as Time;

class BitcoinPriceView extends Ui.View {

   	hidden var mDelta = null;
   	hidden var mPrice = 0.0;
    hidden var mModel;
    
    var graphHeight = 20;  // height in pixels
        

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
    		dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_MEDIUM, "$ " + Lang.format("$1$", [mPrice]), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    	
    	
    		// TODO: draw trend line from historical returns
			var xs = new [5];
			xs[0] = -50;
			xs[1] = -25;
			xs[2] = 0;
			xs[3] = 25;
			xs[4] = 50;
			for(var i = 1 ; i < mDelta.size() ; i++)
			{
				var y = mDelta[i] - mDelta[i-1];
				Sys.println(y);
				dc.drawLine(dc.getWidth()/2 - xs[i-1], dc.getHeight()/2 + 40 + mDelta[i-1], dc.getWidth()/2 - xs[i], dc.getHeight()/2 + 40 + mDelta[i]);
			}
    	}
    	else
    	{
        	dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_MEDIUM, "Bitcoin\nWaiting for data", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
			delta[0] = 0.0;
			for(var i = 1 ; i < bcp.history.size() ; i++)
			{
				delta[i] = bcp.history[i] - bcp.history[i-1];
				if(Math.pow(delta[i], 2) > max)
				{
					max = Math.sqrt(Math.pow(delta[i], 2));
				}
			}
			for(var i = 1 ; i < delta.size() ; i++)  // normalize returns
			{
				delta[i] = (delta[i] / max) * graphHeight;
				
			}
			
			mDelta = delta;
			
        }
        else if (bcp instanceof Lang.String)
        {
            Sys.println(bcp);
        }
        Ui.requestUpdate();
    }

}