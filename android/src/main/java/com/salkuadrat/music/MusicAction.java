package com.salkuadrat.music;

import android.content.Intent;

public class MusicAction {
    static final String PLAY = "play";
    static final String PAUSE = "pause";
    static final String STOP = "stop";
    static final String PREVIOUS = "previous";
    static final String NEXT = "next";
    static final String CANCEL = "cancel";

    static final Intent play = new Intent(PLAY);
    static final Intent pause = new Intent(PAUSE);
    static final Intent stop = new Intent(STOP);
    static final Intent previous = new Intent(PREVIOUS);
    static final Intent next = new Intent(NEXT);
    static final Intent cancel = new Intent(CANCEL);
}
