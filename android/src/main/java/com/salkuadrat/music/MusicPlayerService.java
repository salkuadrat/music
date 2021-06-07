package com.salkuadrat.music;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.media.MediaMetadata;
import android.os.Binder;
import android.os.Build;
import android.os.IBinder;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.media.app.NotificationCompat.MediaStyle;

import java.util.Calendar;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.android.FlutterActivity;

public class MusicPlayerService extends Service {

    class LocalBinder extends Binder {
        MusicPlayerService service = MusicPlayerService.this;
    }

    private NotificationManagerCompat manager;

    private final int notifId = 13372589;
    private final String channelId = "musicplayer";
    private final LocalBinder binder = new LocalBinder();
    private long timeDiff = 0;
    private long timePaused = 0;

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return binder;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.v("MusicPlayerService", "onStartCommand");
        manager = NotificationManagerCompat.from(getApplicationContext());

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            String channelName = "Music Player";
            NotificationChannel channel = new NotificationChannel(
                channelId, channelName, NotificationManager.IMPORTANCE_DEFAULT);
            channel.setSound(null, null);
            channel.enableLights(true);
            channel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);
            manager.createNotificationChannel(channel);
        }

        // Fixing: Context.startForegroundService() did not then call Service.startForeground()
        // Start an empty notification before showing the real one
        showEmptyNotification();
        return START_NOT_STICKY;
    }

    private void showEmptyNotification() {
        MediaSessionCompat session = new MediaSessionCompat(getApplicationContext(), "MusicPlayerService");
        MediaStyle mediaStyle = new MediaStyle().setMediaSession(session.getSessionToken());
        NotificationCompat.Builder builder = new NotificationCompat
            .Builder(getApplicationContext(), channelId)
            .setContentTitle("")
            .setContentText("")
            .setSmallIcon(R.drawable.notification_icon)
            .setStyle(mediaStyle);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setChannelId(channelId);
        }

        startForeground(notifId, builder.build());
    }

    private PendingIntent pendingIntent(int code, Intent intent) {
        return PendingIntent.getBroadcast(
            getApplicationContext(), code, intent, PendingIntent.FLAG_UPDATE_CURRENT);
    }

    private NotificationCompat.Action mediaAction(int icon, int code, String title, Intent intent) {
        PendingIntent pendingIntent = pendingIntent(code, intent);
        return new NotificationCompat.Action.Builder(icon, title, pendingIntent).build();
    }

    /*private NotificationCompat.Action mediaAction(int icon, String title, long action) {
        PendingIntent pendingIntent = MediaButtonReceiver.buildMediaButtonPendingIntent(
            this, action);
        return new NotificationCompat.Action.Builder(icon, title, pendingIntent).build();
    }*/

    void showNotification(Music music) {
        MediaSessionCompat session = music.session;

        if (session == null) {
            return;
        }

        // when music is not playing, detached notification from its service
        // so the notification will become cancellable
        if (!music.isPlaying) {
            detachNotifFromService();
        }

        //Log.v("MusicPlayerService", "Updating Notification...");
        //Log.v("MusicPlayerService", "Position: " + music.position);
        //Log.v("MusicPlayerService", "Duration: " + music.duration);

        MediaMetadataCompat metadata = new MediaMetadataCompat.Builder()
            .putString(MediaMetadata.METADATA_KEY_TITLE, music.title)
            .putString(MediaMetadata.METADATA_KEY_ARTIST, music.artist)
            .putString(MediaMetadata.METADATA_KEY_ALBUM, music.album)
            .putBitmap(MediaMetadata.METADATA_KEY_ART, music.image)
            .putLong(MediaMetadata.METADATA_KEY_DURATION, music.duration)
            .build();

        session.setMetadata(metadata);

        int playbackSpeed = music.isPlaying ? 1 : 0;
        int playbackState = music.isPlaying
            ? PlaybackStateCompat.STATE_PLAYING
            : PlaybackStateCompat.STATE_PAUSED;

        boolean showPrevNext = music.showPrevious || music.showNext;

        PlaybackStateCompat state = new PlaybackStateCompat.Builder()
            .setState(playbackState, music.position, playbackSpeed)
            .setActions(PlaybackStateCompat.ACTION_PLAY_PAUSE |
                PlaybackStateCompat.ACTION_PLAY |
                PlaybackStateCompat.ACTION_PAUSE |
                PlaybackStateCompat.ACTION_SEEK_TO |
                PlaybackStateCompat.ACTION_STOP |
                PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS |
                PlaybackStateCompat.ACTION_SKIP_TO_NEXT)
            .build();

        session.setPlaybackState(state);
        session.setActive(true);

        MediaStyle mediaStyle = new MediaStyle()
            .setMediaSession(session.getSessionToken())
            // For backwards compatibility with Android L and earlier.
            .setShowCancelButton(true)
            .setCancelButtonIntent(pendingIntent(4, MusicAction.stop));

        if (!music.isLoading) {
            if (showPrevNext) {
                mediaStyle.setShowActionsInCompactView(1);
            } else {
                mediaStyle.setShowActionsInCompactView(0);
            }
        }

        NotificationCompat.Builder builder = new NotificationCompat
            .Builder(getApplicationContext(), channelId)
            .setContentTitle(music.artist)
            .setContentText(music.title)
            .setLargeIcon(music.image)
            .setSmallIcon(R.drawable.notification_icon)
            .setOngoing(music.isPlaying)
            .setStyle(mediaStyle);

        int secpos = music.position / 1000;
        int hour = secpos / 3600;
        int minute = (secpos % 3600) / 60;
        int second = secpos % 60;

        Calendar now = Calendar.getInstance();
        now.set(Calendar.HOUR_OF_DAY, minute);
        now.set(Calendar.MINUTE, second);
        now.set(Calendar.SECOND, 0);
        long when = now.getTimeInMillis();
        builder.setUsesChronometer(false);
        builder.setWhen(when);

        /*if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            builder.setUsesChronometer(true);
        } else {
            builder.setUsesChronometer(false);
        }*/

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setChannelId(channelId);
        }

        /*NotificationCompat.Action previous = mediaAction(
            R.drawable.media_previous, "Previous", PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS);
        NotificationCompat.Action pause = mediaAction(
            R.drawable.media_pause, "Pause", PlaybackStateCompat.ACTION_PAUSE);
        NotificationCompat.Action play = mediaAction(
            R.drawable.media_play, "Play", PlaybackStateCompat.ACTION_PLAY);
        NotificationCompat.Action next = mediaAction(
            R.drawable.media_next, "Next", PlaybackStateCompat.ACTION_SKIP_TO_NEXT);*/

        NotificationCompat.Action previous = mediaAction(
            R.drawable.media_previous, 1, "Previous", MusicAction.previous);
        NotificationCompat.Action pause = mediaAction(
            R.drawable.media_pause, 2, "Pause", MusicAction.pause);
        NotificationCompat.Action play = mediaAction(
            R.drawable.media_play, 2, "Play", MusicAction.play);
        NotificationCompat.Action next = mediaAction(
            R.drawable.media_next, 3, "Next", MusicAction.next);

        if (showPrevNext) {
            builder.addAction(previous);
        }

        if (!music.isLoading) {
            if (music.isPlaying) {
                builder.addAction(pause);
            } else {
                builder.addAction(play);
            }
        }

        if (showPrevNext) {
            builder.addAction(next);
        }

        // When notification is deleted (when playback is paused and
        // notification can be deleted) fire MediaButtonPendingIntent
        // with ACTION_PAUSE.
        builder.setDeleteIntent(pendingIntent(2, MusicAction.stop));

        Intent notificationIntent = new Intent(getApplicationContext(), FlutterActivity.class);
        notificationIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        builder.setContentIntent(PendingIntent.getActivity(getApplicationContext(), 0,
                notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT));

        Notification n = builder.build();

        if (manager != null) {
            manager.notify(notifId, builder.build());
        }
    }

    private void detachNotifFromService() {
        //Log.v("MusicPlayerService", "detachNotifFromService");
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_DETACH);
        } else {
            stopForeground(false);
        }
    }

    public void cancel() {
        //Log.v("MusicPlayerService", "cancelNotification");
        if (manager != null) {
            manager.cancel(notifId);
        }
    }
}
