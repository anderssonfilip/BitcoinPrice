using Toybox.Application as App;
using Toybox.System as Sys;

class BitcoinPriceApp extends App.AppBase {

	hidden var mModel;
    hidden var mView;
    
    //! onStart() is called on application start up
    function onStart() {
    
    	Sys.println("");
    	mView = new BitcoinPriceView();
        mModel = new PriceModel(mView.method(:onPrice));
    }

    //! onStop() is called when your application is exiting
    function onStop() {
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ mView ];
    }

}