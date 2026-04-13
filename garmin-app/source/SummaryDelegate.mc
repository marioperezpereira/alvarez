import Toybox.WatchUi;
import Toybox.System;

class SummaryDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() {
        System.exit();
        return true;
    }

    function onSelect() {
        System.exit();
        return true;
    }
}
