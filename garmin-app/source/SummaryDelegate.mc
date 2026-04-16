import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

class SummaryDelegate extends WatchUi.BehaviorDelegate {

    hidden var _view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onBack() {
        System.exit();
        return true;
    }

    function onSelect() {
        // Advance page on tap/select. Exits if already on the last page.
        if (_view.isAtEnd()) {
            System.exit();
            return true;
        }
        _view.nextPage();
        return true;
    }

    function onNextPage() {
        _view.nextPage();
        return true;
    }

    function onPreviousPage() {
        _view.prevPage();
        return true;
    }

    // Swipe gestures on modern CIQ devices (FR970, etc).
    // Swipe right → previous page; swipe left → next page.
    // Swipe up/down ignored so the default behaviour (exit) doesn't fire.
    function onSwipe(event) {
        var dir = event.getDirection();
        if (dir == WatchUi.SWIPE_LEFT) {
            _view.nextPage();
            return true;
        }
        if (dir == WatchUi.SWIPE_RIGHT) {
            _view.prevPage();
            return true;
        }
        return false;
    }

    // Legacy fallback on devices without onNextPage/onPreviousPage routing.
    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_DOWN) {
            _view.nextPage();
            return true;
        }
        if (key == WatchUi.KEY_UP) {
            _view.prevPage();
            return true;
        }
        return false;
    }
}
