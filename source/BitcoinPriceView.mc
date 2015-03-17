using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.System as Sys;

class BitcoinPriceView extends Ui.View {

   	hidden var mPrice = "";
    hidden var mModel;

    //! Load your resources here
    function onLayout(dc) {
        //setLayout(Rez.Layouts.MainLayout(dc));
		mPrice = "Bitcoin\nWaiting for data";
    }

    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_MEDIUM, mPrice, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
   
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    }
    
    
    function onPrice(price)
    {
        if (price instanceof BitcoinPrice)
        {
            mPrice = Lang.format("$ $1$", [price.value]);
            
            // todo: draw trend line from historical prices
        }
        else if (price instanceof Lang.String)
        {
            mPrice = price;
        }
        Ui.requestUpdate();
    }

}