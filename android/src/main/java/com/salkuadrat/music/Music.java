package com.salkuadrat.music;

import android.graphics.Bitmap;
import android.support.v4.media.session.MediaSessionCompat;

public class Music {
    String id = "";
    String title = "";
    String artist = "";
    String album = "";
    Bitmap image;
    String imageUrl = "";
    int duration = 0;
    int position = 0;
    boolean showPrevious = false;
    boolean showNext = false;
    boolean isPlaying = false;
    boolean isLoading = false;
    MediaSessionCompat session;
}
