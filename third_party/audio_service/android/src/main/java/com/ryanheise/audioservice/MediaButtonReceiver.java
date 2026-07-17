package com.ryanheise.audioservice;

import android.content.Context;
import android.content.Intent;

public class MediaButtonReceiver extends androidx.media.session.MediaButtonReceiver {
    public static final String ACTION_NOTIFICATION_DELETE = "com.ryanheise.audioservice.intent.action.ACTION_NOTIFICATION_DELETE";
    public static final String ACTION_NOTIFICATION_CUSTOM = "com.ryanheise.audioservice.intent.action.ACTION_NOTIFICATION_CUSTOM";
    public static final String ACTION_NOTIFICATION_NO_OP = "com.ryanheise.audioservice.intent.action.ACTION_NOTIFICATION_NO_OP";
    public static final String EXTRA_CUSTOM_ACTION = "com.ryanheise.audioservice.extra.CUSTOM_ACTION";
    public static final String EXTRA_CUSTOM_EXTRAS = "com.ryanheise.audioservice.extra.CUSTOM_EXTRAS";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent != null
                && ACTION_NOTIFICATION_NO_OP.equals(intent.getAction())) {
            return;
        }
        if (intent != null
                && ACTION_NOTIFICATION_DELETE.equals(intent.getAction())
                && AudioService.instance != null) {
            AudioService.instance.handleDeleteNotification();
            return;
        }
        if (intent != null
                && Intent.ACTION_MEDIA_BUTTON.equals(intent.getAction())
                && AudioService.instance != null) {
            AudioService.instance.handleActiveMediaButtonIntent(intent);
            return;
        }
        if (intent != null
                && ACTION_NOTIFICATION_CUSTOM.equals(intent.getAction())
                && AudioService.instance != null) {
            AudioService.instance.handleNotificationCustomAction(
                    intent.getStringExtra(EXTRA_CUSTOM_ACTION),
                    intent.getBundleExtra(EXTRA_CUSTOM_EXTRAS));
            return;
        }
        super.onReceive(context, intent);
    }
}
